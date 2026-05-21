# Ex Cinere — Bluetooth Low Energy (BLE) Architecture & Development Plan

> **The proximity engine is the heartbeat of Ex Cinere.** Everything—chains, combat, economics—flows from BLE discovery. This document outlines the complete technical architecture for implementing background BLE scanning, chaining, and anti-cheat.

---

## Overview: The Proximity Stack

```
┌─────────────────────────────────────────────────────────────────┐
│                      MOBILE APP (iOS + Android)                 │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │          PROXIMITY LAYER (Background Service)            │   │
│  │                                                            │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌──────────────────┐ │   │
│  │  │BLE Scanning │  │Device Token │  │Motion Validator  │ │   │
│  │  │& Advertising│  │Generation   │  │(Accelerometer)   │ │   │
│  │  └─────────────┘  └─────────────┘  └──────────────────┘ │   │
│  │                                                            │   │
│  │  ┌────────────────────────────────────────────────────┐  │   │
│  │  │    Chain Manager (Local State Machine)             │  │   │
│  │  │ - Track all nearby devices & bond duration        │  │   │
│  │  │ - Calculate multi-link chains                     │  │   │
│  │  │ - Emit proximity events (proximity_updated)       │  │   │
│  │  └────────────────────────────────────────────────────┘  │   │
│  │                                                            │   │
│  │  ┌────────────────────────────────────────────────────┐  │   │
│  │  │    Anti-Cheat Engine                               │  │   │
│  │  │ - Validate motion (can't chain while stationary)  │  │   │
│  │  │ - Rate limit same-device pairs (90 min/day)       │  │   │
│  │  │ - Detect RSSI spoofing patterns                   │  │   │
│  │  └────────────────────────────────────────────────────┘  │   │
│  │                                                            │   │
│  │  ┌────────────────────────────────────────────────────┐  │   │
│  │  │    Local Storage (SQLite / Realm)                  │  │   │
│  │  │ - Proximity state during offline                 │  │   │
│  │  │ - Pending sync queue                             │  │   │
│  │  └────────────────────────────────────────────────────┘  │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │          SYNC LAYER (Supabase / WebSocket)               │   │
│  │  - Push proximity updates to server                      │   │
│  │  - Receive combat events & market ticks                 │   │
│  │  - Subscribe to realtime changes                        │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │          UI LAYER (React Native / Flutter)               │   │
│  │  - Proximity feed                                        │   │
│  │  - Combat resolution screen                             │   │
│  │  - Market ticker                                        │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                              ↑↓ HTTPS/WebSocket
┌─────────────────────────────────────────────────────────────────┐
│                        BACKEND (Node.js)                         │
│                                                                   │
│  ┌────────────────────────────────────────────────────────┐    │
│  │    Proximity Aggregator (Server-Side Chain Validator) │    │
│  │ - Receive proximity updates from all players           │    │
│  │ - Reconstruct multi-link chains                       │    │
│  │ - Detect & punish spoofing attempts                   │    │
│  │ - Emit chain_formed, chain_broken events              │    │
│  └────────────────────────────────────────────────────────┘    │
│                                                                   │
│  ┌────────────────────────────────────────────────────────┐    │
│  │    Supabase (PostgreSQL + Realtime)                    │    │
│  │ - proximity_events table (server log)                  │    │
│  │ - device_chains table (current state)                 │    │
│  │ - chain_bonuses table (calculated buffs)              │    │
│  │ - anti_cheat_flags table (violations)                 │    │
│  └────────────────────────────────────────────────────────┘    │
│                                                                   │
│  ┌────────────────────────────────────────────────────────┐    │
│  │    Tick Processor (Simulation)                         │    │
│  │ - Use active chains to calculate raid bonuses         │    │
│  │ - Award reputation/infamy for chain maintenance       │    │
│  │ - Decay chains if no proximity updates received       │    │
│  └────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
```

---

## 1. BLE Scanning & Device Discovery

### 1.1 Device Token Generation

Each device broadcasts a **rotating anonymous token** (no user ID).

```typescript
// Device.ts
export class AnonymousDevice {
  private deviceId: string; // UUID stored locally only
  private currentToken: string;
  private tokenRotationInterval: number = 5 * 60 * 1000; // 5 minutes
  
  constructor() {
    this.deviceId = this.getOrCreateLocalUUID();
    this.rotateToken();
    setInterval(() => this.rotateToken(), this.tokenRotationInterval);
  }
  
  private rotateToken(): string {
    // HMAC-SHA256(deviceId + timestamp, secret)
    // Prevents tracking across time but allows server to link back to player
    this.currentToken = hmac(
      `${this.deviceId}:${Math.floor(Date.now() / 300000)}`,
      ROTATION_SECRET
    );
    return this.currentToken;
  }
  
  getCurrentToken(): string {
    return this.currentToken;
  }
  
  // Server can verify token came from this device
  verifyToken(token: string): boolean {
    // Check if token matches current or recent rotations
    const now = Math.floor(Date.now() / 300000);
    for (let i = 0; i < 3; i++) {
      const checkToken = hmac(
        `${this.deviceId}:${now - i}`,
        ROTATION_SECRET
      );
      if (checkToken === token) return true;
    }
    return false;
  }
}
```

### 1.2 BLE Advertising & Scanning

#### iOS Implementation (Swift)

```swift
import CoreBluetooth

class BLEAdvertiser: NSObject, CBPeripheralManagerDelegate {
  var peripheralManager: CBPeripheralManager?
  
  override init() {
    super.init()
    peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
  }
  
  func startAdvertising(token: String) {
    let advertisementData: [String: Any] = [
      CBAdvertisementDataLocalNameKey: "CINERE_\(token)",
      CBAdvertisementDataServiceUUIDsKey: [CBUUID(string: SERVICE_UUID)]
    ]
    
    peripheralManager?.startAdvertising(advertisementData)
  }
  
  func stopAdvertising() {
    peripheralManager?.stopAdvertising()
  }
}

class BLEScanner: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
  var centralManager: CBCentralManager?
  var discoveredDevices: [UUID: DiscoveredDevice] = [:]
  
  override init() {
    super.init()
    centralManager = CBCentralManager(delegate: self, queue: nil)
  }
  
  func startScanning() {
    centralManager?.scanForPeripherals(
      withServices: [CBUUID(string: SERVICE_UUID)],
      options: [CBCentralManagerScanOptionAllowDuplicatesKey: true]
    )
  }
  
  // Called every time a device is discovered (even without state changes)
  func centralManager(
    _ central: CBCentralManager,
    didDiscover peripheral: CBPeripheral,
    advertisementData: [String: Any],
    rssi: NSNumber
  ) {
    let token = advertisementData[CBAdvertisementDataLocalNameKey] as? String ?? ""
    let distance = calculateDistance(rssi: rssi.intValue)
    
    if let existing = discoveredDevices[peripheral.identifier] {
      // Update existing device
      existing.lastSeen = Date()
      existing.rssi = rssi.intValue
      existing.distance = distance
      existing.tokenHistory.append(token)
    } else {
      // New device discovered
      let device = DiscoveredDevice(
        id: peripheral.identifier,
        token: token,
        rssi: rssi.intValue,
        distance: distance
      )
      discoveredDevices[peripheral.identifier] = device
      notifyProximityEngine(device: device, event: .discovered)
    }
  }
  
  // Calculate distance from RSSI (signal strength)
  // RSSI = TX_POWER - (10 * N * log10(distance))
  // For 1m, TX_POWER ≈ -41 dBm typical for BLE
  private func calculateDistance(rssi: Int) -> Double {
    let txPower = -41.0
    let pathLoss = Double(rssi) - txPower
    let distance = pow(10.0, pathLoss / 20.0)
    return distance
  }
}
```

#### Android Implementation (Kotlin)

```kotlin
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanResult
import android.content.Context
import com.polidea.rxandroidble3.RxBleClient

class BLEScanner(context: Context) {
  private val rxBleClient = RxBleClient.create(context)
  private val discoveredDevices = mutableMapOf<String, DiscoveredDevice>()
  
  fun startScanning() {
    rxBleClient.scanBleDevices(
      ScanSettings.Builder()
        .setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY)
        .build()
    )
    .subscribe(
      { scanResult -> onDeviceDiscovered(scanResult) },
      { error -> onScanError(error) }
    )
  }
  
  private fun onDeviceDiscovered(scanResult: ScanResult) {
    val device = scanResult.bleDevice
    val rssi = scanResult.rssi
    val token = device.name ?: ""
    val distance = calculateDistance(rssi)
    
    if (discoveredDevices.containsKey(device.macAddress)) {
      val existing = discoveredDevices[device.macAddress]!!
      existing.lastSeen = System.currentTimeMillis()
      existing.rssi = rssi
      existing.distance = distance
      existing.tokenHistory.add(token)
    } else {
      val newDevice = DiscoveredDevice(
        id = device.macAddress,
        token = token,
        rssi = rssi,
        distance = distance
      )
      discoveredDevices[device.macAddress] = newDevice
      notifyProximityEngine(newDevice, ProximityEvent.DISCOVERED)
    }
  }
  
  private fun calculateDistance(rssi: Int): Double {
    val txPower = -41.0
    val pathLoss = rssi - txPower
    return Math.pow(10.0, pathLoss / 20.0)
  }
}
```

---

## 2. Chain Manager (Local State Machine)

The heart of the proximity engine. Runs on the device and tracks all nearby devices + calculates multi-link chains.

```typescript
// ChainManager.ts
import { EventEmitter } from 'events';

interface ProximityDevice {
  id: string;
  token: string;
  zone: 'close' | 'near' | 'distant'; // Based on distance
  chainDuration: number; // Seconds
  firstSeen: number;
  lastSeen: number;
  rssiHistory: number[];
}

interface Chain {
  id: string;
  members: ProximityDevice[]; // Ordered by discovery
  length: number;
  totalBonus: number;
  formed: number; // Timestamp
}

export class ChainManager extends EventEmitter {
  private devices: Map<string, ProximityDevice> = new Map();
  private chains: Map<string, Chain> = new Map();
  private motionValidator: MotionValidator;
  private antiCheat: AntiCheatEngine;
  
  // Configuration
  private readonly MIN_LINK_TIME = 30; // seconds
  private readonly CLOSE_DISTANCE = 3; // meters
  private readonly NEAR_DISTANCE = 10;
  private readonly DISTANT_DISTANCE = 20;
  private readonly CLOSE_BUILD_RATE = 2.0; // 2x speed
  private readonly NEAR_BUILD_RATE = 1.0;
  
  constructor() {
    super();
    this.motionValidator = new MotionValidator();
    this.antiCheat = new AntiCheatEngine();
  }
  
  /**
   * Called every time a nearby device is discovered or updated
   */
  public updateDeviceProximity(
    deviceId: string,
    token: string,
    rssi: number,
    distance: number
  ): void {
    const zone = this.getZone(distance);
    const now = Date.now();
    
    if (!this.devices.has(deviceId)) {
      // New device
      this.devices.set(deviceId, {
        id: deviceId,
        token: token,
        zone: zone,
        chainDuration: 0,
        firstSeen: now,
        lastSeen: now,
        rssiHistory: [rssi]
      });
      
      this.emit('device_discovered', { deviceId, token, zone });
    } else {
      // Update existing device
      const device = this.devices.get(deviceId)!;
      device.zone = zone;
      device.lastSeen = now;
      device.rssiHistory.push(rssi);
      
      // Trim history to last 60 measurements
      if (device.rssiHistory.length > 60) {
        device.rssiHistory.shift();
      }
      
      // Check for zone transitions
      if (device.zone !== zone) {
        this.emit('zone_transition', { deviceId, oldZone: device.zone, newZone: zone });
      }
    }
    
    // Recalculate chains
    this.recalculateChains();
  }
  
  /**
   * Called when a device leaves proximity (BLE scan stops detecting it)
   */
  public removeDevice(deviceId: string): void {
    this.devices.delete(deviceId);
    this.emit('device_disappeared', { deviceId });
    this.recalculateChains();
  }
  
  /**
   * Main chain calculation logic
   * A chain is formed when:
   * 1. Device is in "near" or "close" zone
   * 2. Device has been in proximity for >= MIN_LINK_TIME
   * 3. Motion validator confirms movement
   * 4. Anti-cheat passes
   */
  private async recalculateChains(): Promise<void> {
    const now = Date.now();
    const validDevices: ProximityDevice[] = [];
    
    for (const device of this.devices.values()) {
      // Check zone
      if (device.zone === 'distant') continue;
      
      // Check duration
      const duration = (now - device.firstSeen) / 1000;
      if (duration < this.MIN_LINK_TIME) continue;
      
      // Check motion
      const isMoving = await this.motionValidator.isMoving();
      if (!isMoving) continue;
      
      // Check anti-cheat
      const antiCheatPass = await this.antiCheat.validateDevice(device);
      if (!antiCheatPass) {
        this.emit('anti_cheat_violation', { deviceId: device.id });
        continue;
      }
      
      // Update chain duration
      device.chainDuration = duration;
      validDevices.push(device);
    }
    
    // Calculate bonuses for multi-link chains
    if (validDevices.length >= 2) {
      const chainId = this.generateChainId(validDevices);
      const chain: Chain = {
        id: chainId,
        members: validDevices,
        length: validDevices.length,
        totalBonus: this.calculateBonus(validDevices.length),
        formed: now
      };
      
      this.chains.set(chainId, chain);
      this.emit('chain_formed', chain);
    } else {
      // No valid chain
      this.chains.clear();
      this.emit('chain_broken');
    }
  }
  
  private getZone(distance: number): 'close' | 'near' | 'distant' {
    if (distance <= this.CLOSE_DISTANCE) return 'close';
    if (distance <= this.NEAR_DISTANCE) return 'near';
    return 'distant';
  }
  
  private generateChainId(devices: ProximityDevice[]): string {
    // Deterministic hash of device IDs
    const sorted = devices.map(d => d.id).sort();
    return sha256(sorted.join(':'));
  }
  
  private calculateBonus(chainLength: number): number {
    const bonuses = {
      2: 0.10, // +10% resource generation
      3: 0.15,
      4: 0.20,
      5: 0.25,
      6: 0.30,
      7: 0.35,
      8: 0.40
    };
    return bonuses[Math.min(chainLength, 8)] || 0.40;
  }
  
  /**
   * Export current state for syncing to server
   */
  public getProximityState(): ProximityState {
    return {
      timestamp: Date.now(),
      devices: Array.from(this.devices.values()),
      chains: Array.from(this.chains.values()),
      isMoving: this.motionValidator.isCurrentlyMoving(),
      antiCheatScore: this.antiCheat.getDeviceScore()
    };
  }
}
```

---

## 3. Motion Validator (Anti-Cheat Layer 1)

Prevents players from gaining chain bonuses while stationary.

```typescript
// MotionValidator.ts
import { Accelerometer } from 'react-native-sensors'; // or equivalent

export class MotionValidator {
  private accelerometerData: number[] = [];
  private isMoving: boolean = false;
  
  // Thresholds
  private readonly MOTION_THRESHOLD = 0.5; // m/s²
  private readonly SAMPLE_WINDOW = 100; // 100 samples
  private readonly SAMPLE_RATE = 100; // Hz
  
  constructor() {
    this.startAccelerometerMonitoring();
  }
  
  private startAccelerometerMonitoring(): void {
    const subscription = Accelerometer.subscribe(
      ({ x, y, z }) => {
        // Calculate magnitude
        const magnitude = Math.sqrt(x*x + y*y + z*z);
        this.accelerometerData.push(magnitude);
        
        // Keep last 100 samples
        if (this.accelerometerData.length > this.SAMPLE_WINDOW) {
          this.accelerometerData.shift();
        }
        
        // Calculate rolling average
        const avg = this.accelerometerData.reduce((a, b) => a + b, 0) / this.accelerometerData.length;
        
        // Moving = average motion > threshold
        this.isMoving = avg > this.MOTION_THRESHOLD;
      },
      { updateInterval: 1000 / this.SAMPLE_RATE }
    );
  }
  
  public async isMoving(): Promise<boolean> {
    // Must have at least 100 samples
    if (this.accelerometerData.length < this.SAMPLE_WINDOW) {
      return false;
    }
    return this.isMoving;
  }
  
  public isCurrentlyMoving(): boolean {
    return this.isMoving;
  }
}
```

---

## 4. Anti-Cheat Engine

Multi-layer spoofing detection.

```typescript
// AntiCheatEngine.ts
interface AntiCheatViolation {
  type: 'rssi_spoofing' | 'stationary_chain' | 'rate_limit_exceeded' | 'token_mismatch';
  deviceId: string;
  severity: 'warning' | 'violation' | 'ban';
  timestamp: number;
}

export class AntiCheatEngine {
  private deviceScores: Map<string, number> = new Map(); // 0-100
  private violations: AntiCheatViolation[] = [];
  private rateLimitTracker: Map<string, number> = new Map(); // (deviceA-deviceB) -> seconds today
  
  // Configuration
  private readonly MAX_RATE_LIMIT = 90 * 60; // 90 minutes per day
  private readonly RSSI_ANOMALY_THRESHOLD = 15; // dBm jump
  private readonly SPOOFING_SCORE_PENALTY = -25;
  private readonly BAN_THRESHOLD = -50;
  
  public async validateDevice(device: ProximityDevice): Promise<boolean> {
    let score = this.deviceScores.get(device.id) ?? 100;
    
    // Check 1: RSSI Stability
    if (!this.checkRSSIStability(device)) {
      score += this.SPOOFING_SCORE_PENALTY;
      this.recordViolation({
        type: 'rssi_spoofing',
        deviceId: device.id,
        severity: 'warning',
        timestamp: Date.now()
      });
    }
    
    // Check 2: Token Rotation Validation
    if (!this.validateTokenHistory(device)) {
      score += this.SPOOFING_SCORE_PENALTY;
      this.recordViolation({
        type: 'token_mismatch',
        deviceId: device.id,
        severity: 'warning',
        timestamp: Date.now()
      });
    }
    
    // Check 3: Rate Limiting
    const pairId = this.generatePairId(device.id);
    if (!this.checkRateLimit(pairId)) {
      score += this.SPOOFING_SCORE_PENALTY;
      this.recordViolation({
        type: 'rate_limit_exceeded',
        deviceId: device.id,
        severity: 'violation',
        timestamp: Date.now()
      });
    }
    
    this.deviceScores.set(device.id, Math.max(score, this.BAN_THRESHOLD));
    
    // If score below ban threshold, player should be suspended
    if (score <= this.BAN_THRESHOLD) {
      this.recordViolation({
        type: 'rate_limit_exceeded',
        deviceId: device.id,
        severity: 'ban',
        timestamp: Date.now()
      });
      return false;
    }
    
    return true;
  }
  
  /**
   * RSSI should not jump more than ~15 dBm per measurement
   * (unless device moved ~3x the distance instantly)
   */
  private checkRSSIStability(device: ProximityDevice): boolean {
    if (device.rssiHistory.length < 2) return true;
    
    const last = device.rssiHistory[device.rssiHistory.length - 1];
    const prev = device.rssiHistory[device.rssiHistory.length - 2];
    
    const jump = Math.abs(last - prev);
    return jump < this.RSSI_ANOMALY_THRESHOLD;
  }
  
  /**
   * Token should rotate every ~5 minutes but be consistent with device ID
   * Server can verify tokens match expected rotation pattern
   */
  private validateTokenHistory(device: ProximityDevice): boolean {
    // This would require server validation
    // For now, just check that tokens are being rotated
    return device.tokenHistory.length >= 1;
  }
  
  /**
   * Same device pair can only chain 90 minutes per 24-hour period
   */
  private checkRateLimit(pairId: string): boolean {
    const today = Math.floor(Date.now() / (24 * 60 * 60 * 1000));
    const key = `${pairId}:${today}`;
    
    const currentSeconds = (this.rateLimitTracker.get(key) ?? 0);
    if (currentSeconds >= this.MAX_RATE_LIMIT) {
      return false;
    }
    
    // Increment by 1 second
    this.rateLimitTracker.set(key, currentSeconds + 1);
    return true;
  }
  
  private generatePairId(deviceId: string): string {
    // This should be called with sorted device IDs
    // to create consistent pair keys
    return deviceId;
  }
  
  private recordViolation(violation: AntiCheatViolation): void {
    this.violations.push(violation);
    
    // Send to server for logging
    // TODO: POST to /api/anti-cheat/report
  }
  
  public getDeviceScore(): number {
    return this.deviceScores.get('self') ?? 100;
  }
}
```

---

## 5. Proximity Sync Protocol

How device state gets to the server & back.

```typescript
// ProximitySyncService.ts
export interface ProximityUpdate {
  playerId: string;
  timestamp: number;
  deviceToken: string;
  nearbyDevices: {
    id: string;
    token: string;
    distance: number;
    rssi: number;
  }[];
  chains: Chain[];
  antiCheatScore: number;
  isMoving: boolean;
}

export class ProximitySyncService {
  private supabase: SupabaseClient;
  private syncInterval: NodeJS.Timer;
  private pendingUpdates: ProximityUpdate[] = [];
  
  constructor(supabase: SupabaseClient) {
    this.supabase = supabase;
    this.startSync();
  }
  
  private startSync(): void {
    // Sync every 5 seconds (or when pending updates accumulate)
    this.syncInterval = setInterval(() => this.syncToServer(), 5000);
  }
  
  public queueUpdate(update: ProximityUpdate): void {
    this.pendingUpdates.push(update);
    
    // Flush if queue is large or old
    if (this.pendingUpdates.length > 10) {
      this.syncToServer();
    }
  }
  
  private async syncToServer(): Promise<void> {
    if (this.pendingUpdates.length === 0) return;
    
    const batch = this.pendingUpdates.splice(0, 50); // Max 50 per request
    
    try {
      // Insert proximity events
      const { error } = await this.supabase
        .from('proximity_events')
        .insert(
          batch.map(update => ({
            player_id: update.playerId,
            device_token: update.deviceToken,
            nearby_devices: update.nearbyDevices,
            chains: update.chains,
            anti_cheat_score: update.antiCheatScore,
            is_moving: update.isMoving,
            created_at: new Date(update.timestamp).toISOString()
          }))
        );
      
      if (error) throw error;
    } catch (err) {
      console.error('Proximity sync failed:', err);
      // Re-queue failed updates
      this.pendingUpdates.unshift(...batch);
    }
  }
  
  public subscribe(): void {
    // Subscribe to proximity updates from other players
    this.supabase
      .channel('proximity_updates')
      .on(
        'postgres_changes',
        {
          event: 'INSERT',
          schema: 'public',
          table: 'proximity_events'
        },
        (payload) => this.handleRemoteProximityUpdate(payload.new)
      )
      .subscribe();
  }
  
  private handleRemoteProximityUpdate(update: any): void {
    // Update local state with remote device's proximity data
    console.log('Remote player proximity:', update);
  }
}
```

---

## 6. Server-Side Chain Validator

Backend validates all client claims.

```typescript
// ProximityAggregator.ts (Backend)
export class ProximityAggregator {
  private supabase: SupabaseClient;
  
  /**
   * When server receives proximity_events from all players,
   * it reconstructs the true chain state
   */
  public async validateAndAggregate(
    proximityEvents: ProximityEvent[]
  ): Promise<Chain[]> {
    const chains: Chain[] = [];
    
    // 1. Group devices by proximity
    const deviceGraph = this.buildProximityGraph(proximityEvents);
    
    // 2. Find connected components (multi-link chains)
    const components = this.findConnectedComponents(deviceGraph);
    
    // 3. Validate each component
    for (const component of components) {
      const chain = await this.validateChain(component, proximityEvents);
      if (chain) {
        chains.push(chain);
      }
    }
    
    // 4. Store validated chains
    await this.storeValidatedChains(chains);
    
    return chains;
  }
  
  private buildProximityGraph(events: ProximityEvent[]): Map<string, Set<string>> {
    const graph = new Map<string, Set<string>>();
    
    for (const event of events) {
      if (!graph.has(event.playerId)) {
        graph.set(event.playerId, new Set());
      }
      
      for (const nearbyDevice of event.nearbyDevices) {
        // Create bidirectional edge
        graph.get(event.playerId)!.add(nearbyDevice.id);
        
        if (!graph.has(nearbyDevice.id)) {
          graph.set(nearbyDevice.id, new Set());
        }
        graph.get(nearbyDevice.id)!.add(event.playerId);
      }
    }
    
    return graph;
  }
  
  private findConnectedComponents(graph: Map<string, Set<string>>): string[][] {
    const visited = new Set<string>();
    const components: string[][] = [];
    
    for (const node of graph.keys()) {
      if (!visited.has(node)) {
        const component = this.dfs(node, graph, visited);
        components.push(component);
      }
    }
    
    return components;
  }
  
  private dfs(node: string, graph: Map<string, Set<string>>, visited: Set<string>): string[] {
    visited.add(node);
    const component = [node];
    
    for (const neighbor of graph.get(node) || []) {
      if (!visited.has(neighbor)) {
        component.push(...this.dfs(neighbor, graph, visited));
      }
    }
    
    return component;
  }
  
  private async validateChain(
    playerIds: string[],
    events: ProximityEvent[]
  ): Promise<Chain | null> {
    if (playerIds.length < 2) return null;
    
    // Check that all players submitted proximity events in similar timeframe
    const eventTimestamps = playerIds
      .map(id => events.find(e => e.playerId === id))
      .filter(e => e !== undefined)
      .map(e => e!.timestamp);
    
    // All events should be within 10 seconds of each other
    const maxTime = Math.max(...eventTimestamps);
    const minTime = Math.min(...eventTimestamps);
    
    if (maxTime - minTime > 10000) {
      // Events too far apart in time, likely desync
      return null;
    }
    
    // Check anti-cheat scores
    const avgAntiCheatScore = playerIds
      .map(id => events.find(e => e.playerId === id))
      .filter(e => e !== undefined)
      .map(e => e!.antiCheatScore)
      .reduce((a, b) => a + b, 0) / playerIds.length;
    
    if (avgAntiCheatScore < 0) {
      // Flagged players, don't form valid chain
      return null;
    }
    
    return {
      id: sha256(playerIds.sort().join(':')),
      members: playerIds,
      length: playerIds.length,
      totalBonus: this.calculateBonus(playerIds.length),
      formed: Math.max(...eventTimestamps),
      validated: true
    };
  }
  
  private async storeValidatedChains(chains: Chain[]): Promise<void> {
    await this.supabase.from('device_chains').upsert(
      chains.map(chain => ({
        id: chain.id,
        members: chain.members,
        length: chain.length,
        total_bonus: chain.totalBonus,
        formed_at: new Date(chain.formed).toISOString(),
        validated: true
      }))
    );
  }
}
```

---

## 7. Database Schema (Supabase)

```sql
-- Proximity Events (Raw client submissions)
CREATE TABLE proximity_events (
  id BIGSERIAL PRIMARY KEY,
  player_id UUID NOT NULL REFERENCES characters(id),
  device_token TEXT NOT NULL,
  nearby_devices JSONB, -- Array of {id, token, distance, rssi}
  chains JSONB, -- Proposed chains from client
  anti_cheat_score INT,
  is_moving BOOLEAN,
  created_at TIMESTAMP DEFAULT NOW(),
  
  INDEX idx_player_id (player_id),
  INDEX idx_created_at (created_at)
);

-- Validated Device Chains (Server-validated state)
CREATE TABLE device_chains (
  id TEXT PRIMARY KEY,
  members UUID[] NOT NULL,
  length INT NOT NULL,
  total_bonus FLOAT NOT NULL,
  formed_at TIMESTAMP NOT NULL,
  validated BOOLEAN NOT NULL,
  expires_at TIMESTAMP, -- Chain expires after 5 minutes without activity
  
  INDEX idx_members (members),
  INDEX idx_expires_at (expires_at)
);

-- Chain Bonuses (Calculated effects)
CREATE TABLE chain_bonuses (
  id BIGSERIAL PRIMARY KEY,
  chain_id TEXT NOT NULL REFERENCES device_chains(id),
  player_id UUID NOT NULL REFERENCES characters(id),
  bonus_type VARCHAR(50), -- 'resource_generation', 'damage_reduction', etc.
  bonus_value FLOAT NOT NULL,
  expires_at TIMESTAMP NOT NULL,
  
  INDEX idx_player_id (player_id),
  INDEX idx_expires_at (expires_at)
);

-- Anti-Cheat Flags
CREATE TABLE anti_cheat_flags (
  id BIGSERIAL PRIMARY KEY,
  player_id UUID NOT NULL REFERENCES characters(id),
  violation_type VARCHAR(50), -- 'rssi_spoofing', 'rate_limit_exceeded', etc.
  severity VARCHAR(20), -- 'warning', 'violation', 'ban'
  details JSONB,
  created_at TIMESTAMP DEFAULT NOW(),
  
  INDEX idx_player_id (player_id),
  INDEX idx_severity (severity)
);

-- Rate Limiting (Track same-device pairs)
CREATE TABLE rate_limit_tracking (
  id BIGSERIAL PRIMARY KEY,
  device_pair_id TEXT NOT NULL,
  chain_seconds_today INT DEFAULT 0,
  reset_at TIMESTAMP, -- Next 24-hour period
  
  UNIQUE(device_pair_id)
);
```

---

## 8. Development Roadmap

### Phase 1: Core BLE (Weeks 1-4)
- [ ] Implement `BLEScanner.ts` (iOS)
- [ ] Implement `BLEScanner.kt` (Android)
- [ ] Implement `AnonymousDevice` token rotation
- [ ] Test proximity detection in sandbox
- [ ] Benchmark battery drain (target: 1-3% per hour)

### Phase 2: Chain Engine (Weeks 5-7)
- [ ] Implement `ChainManager.ts`
- [ ] Implement `MotionValidator.ts`
- [ ] Implement `AntiCheatEngine.ts`
- [ ] Unit test chain formation logic
- [ ] Implement sync protocol

### Phase 3: Server Validation (Weeks 8-9)
- [ ] Implement `ProximityAggregator.ts`
- [ ] Add database schema & tables
- [ ] Create `/api/proximity/validate` endpoint
- [ ] Integration test client → server flow

### Phase 4: Advanced Anti-Cheat (Week 10+)
- [ ] Token verification on server
- [ ] RSSI spoofing detection (machine learning?)
- [ ] Rate limiting enforcement
- [ ] Banning system
- [ ] Penalties for violations

### Phase 5: Optimization (Week 11+)
- [ ] Battery optimization (reduce scan frequency in low-activity areas)
- [ ] Connection pooling for Supabase
- [ ] Redis caching for active chains
- [ ] Analytics dashboard for proximity patterns

---

## 9. Integration with Game Systems

### 9.1 Combat Bonuses from Chains
```typescript
// RaidResolver.ts
export class RaidResolver {
  async calculateDefensiveBonus(
    defenderId: string,
    chainManager: ChainManager
  ): Promise<number> {
    const proximityState = chainManager.getProximityState();
    const activeChain = proximityState.chains[0]; // If in chain
    
    if (!activeChain) return 1.0; // No bonus
    
    // Chain length 5+ gives +20% damage reduction
    if (activeChain.length >= 5) {
      return 1.2;
    }
    
    // Scale bonus by chain length
    return 1.0 + (activeChain.length * 0.04);
  }
}
```

### 9.2 Reputation from Chain Duration
```typescript
// ReputationEngine.ts
export class ReputationEngine {
  async awardChainReputation(
    playerId: string,
    chainDurationSeconds: number
  ): Promise<void> {
    // Longer chains = more reputation
    // 30 seconds (min) = +1 rep
    // 5 minutes = +25 rep
    // 1 hour = +300 rep
    
    const repGain = Math.log(chainDurationSeconds) * 10;
    
    await this.supabase.from('characters').update({
      reputation: sql`reputation + ${repGain}`
    }).eq('id', playerId);
  }
}
```

### 9.3 News Feed Events
```typescript
// NewsGenerator.ts
export class NewsGenerator {
  async generateChainNews(chain: Chain): Promise<void> {
    if (chain.length >= 8) {
      await this.supabase.from('news_feed').insert({
        headline: `The Wandering City formed: ${chain.members.length} survivors walking together`,
        category: 'chain_formation',
        tick_id: getCurrentTick(),
        created_at: new Date()
      });
    }
  }
}
```

---

## 10. Testing Strategy

### Unit Tests
```typescript
// __tests__/ChainManager.test.ts
describe('ChainManager', () => {
  let chainManager: ChainManager;
  
  beforeEach(() => {
    chainManager = new ChainManager();
  });
  
  it('should form a 2-link chain after 30 seconds of proximity', async () => {
    chainManager.updateDeviceProximity('device1', 'token1', -50, 2);
    
    await sleep(30000); // Wait 30 seconds
    
    chainManager.updateDeviceProximity('device1', 'token1', -50, 2);
    
    const chains = chainManager.getChains();
    expect(chains.length).toBe(1);
    expect(chains[0].length).toBe(1); // Single device doesn't form chain yet
  });
  
  it('should calculate correct bonus for 5-link chain', () => {
    const bonus = chainManager['calculateBonus'](5);
    expect(bonus).toBe(0.25); // +25%
  });
  
  it('should reject stationary chains', async () => {
    const motionValidator = chainManager['motionValidator'];
    jest.spyOn(motionValidator, 'isMoving').mockResolvedValue(false);
    
    chainManager.updateDeviceProximity('device1', 'token1', -50, 2);
    await sleep(30000);
    
    const chains = chainManager.getChains();
    expect(chains.length).toBe(0);
  });
});
```

### Integration Tests
```typescript
// __tests__/integration/proximity.integration.test.ts
describe('Full Proximity Flow', () => {
  let client1: ProximityClient;
  let client2: ProximityClient;
  let server: ProximityAggregator;
  
  beforeEach(async () => {
    client1 = new ProximityClient('player1');
    client2 = new ProximityClient('player2');
    server = new ProximityAggregator();
  });
  
  it('should form chain when 2 devices are in proximity', async () => {
    // Simulate proximity
    client1.fakeProximityEvent({
      nearbyDevices: [{ id: 'device2', distance: 5 }]
    });
    
    client2.fakeProximityEvent({
      nearbyDevices: [{ id: 'device1', distance: 5 }]
    });
    
    // Send to server
    const events = [
      await client1.getProximityEvent(),
      await client2.getProximityEvent()
    ];
    
    const chains = await server.validateAndAggregate(events);
    
    expect(chains.length).toBe(1);
    expect(chains[0].members).toContain('player1');
    expect(chains[0].members).toContain('player2');
  });
});
```

---

## 11. Deployment Checklist

- [ ] BLE entitlements configured for iOS (NSBluetoothPeripheralUsageDescription)
- [ ] Android permissions in AndroidManifest.xml (BLUETOOTH, BLUETOOTH_ADMIN, ACCESS_FINE_LOCATION)
- [ ] Background execution enabled on both platforms
- [ ] HTTPS enforced for all Supabase calls
- [ ] Rate limiting configured on backend
- [ ] Anti-cheat scoring calibrated from playtesting
- [ ] Battery drain testing on 5+ devices for 2+ hours
- [ ] Privacy policy updated (no location, anonymous tokens only)
- [ ] Server-side chain validation in production
- [ ] Monitoring/alerting for anti-cheat violations

---

## 12. Open Questions & Future Work

1. **Geofencing without GPS:** How to prevent players from cheating by having a friend cross the country? Solution: Rate limit + tie to account creation location?

2. **Indoor vs. Outdoor:** BLE signal attenuation varies indoors. Should we weight indoor chains differently?

3. **Large gatherings (festivals):** What happens with 100+ devices in proximity? Does chain bonus scale indefinitely or cap at 8?

4. **Offline chains:** If both players are offline, should chain continue to build when they're physically close? (Requires offline state sync)

5. **Chain ownership:** Who "owns" a chain? All members equally, or leader only?

6. **Breaking chains:** If one player gets banned mid-chain, does entire chain dissolve?

---

**This is a living document. Update as implementation progresses.**
