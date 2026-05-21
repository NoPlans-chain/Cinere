import type { Metadata } from 'next'
import './globals.css'

export const metadata: Metadata = {
  title: 'EX CINERE',
  description: 'Next.js integration for the Ex Cinere simulation',
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  )
}
