'use client'
import './globals.css'
import { Inter } from 'next/font/google'
import { AuthContextProvider } from '@/lib/AuthContext'
import Sidebar from '@/components/Sidebar'
import { usePathname } from 'next/navigation'

const inter = Inter({ subsets: ['latin'] })

export default function RootLayout({ children }) {
  const pathname = usePathname()
  const noSidebarRoutes = ['/login']
  const showSidebar = !noSidebarRoutes.includes(pathname)

  return (
    <html lang="en">
      <body className={`${inter.className} bg-gray-100 text-gray-900`}>
        <AuthContextProvider>
          <div className="min-h-screen">
            {/* Sidebar */}
            {showSidebar && <Sidebar />}

            {/* Konten Utama */}
            <main
              className={`min-h-screen transition-all duration-300 ${
                showSidebar ? 'pl-64' : 'w-full'
              }`}
            >
              {children}
            </main>
          </div>
        </AuthContextProvider>
      </body>
    </html>
  )
}
