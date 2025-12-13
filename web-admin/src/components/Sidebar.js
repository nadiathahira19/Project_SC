// src/components/Sidebar.js
'use client'

import { useState, useEffect } from 'react'
import Link from 'next/link'
import { usePathname, useRouter } from 'next/navigation'
import {
  LayoutDashboard,
  Users,
  Trash2,
  Gift,
  Activity,
  MapPin,
  LogOut,
  Shield,
} from 'lucide-react'
import { signOut } from 'firebase/auth'
import { auth, db } from '@/lib/firebase'
import { doc, getDoc } from 'firebase/firestore'
import { useAuth } from '@/lib/AuthContext'

export default function Sidebar() {
  const pathname = usePathname()
  const router = useRouter()
  const { user } = useAuth()
  const [userRole, setUserRole] = useState(null)

  useEffect(() => {
    // Ambil role user dari Firestore setelah user berhasil login
    const checkRole = async () => {
      if (user) {
        const docSnap = await getDoc(doc(db, 'users', user.uid))
        if (docSnap.exists()) {
          setUserRole(docSnap.data().role)
        }
      }
    }
    checkRole()
  }, [user])

  const handleLogout = async () => {
    try {
      // Logout lalu redirect ke halaman login
      await signOut(auth)
      router.push('/login')
    } catch (error) {
      console.error('Gagal logout:', error)
    }
  }

  // Daftar menu untuk sidebar
  const menuItems = [
    { name: 'Dashboard', href: '/', icon: LayoutDashboard },
    { name: 'Data User', href: '/users', icon: Users },
    { name: 'Monitoring Scan', href: '/scan-history', icon: Activity },
    { name: 'Kelola Reward', href: '/rewards', icon: Gift },
    { name: 'Kelola Tong Sampah', href: '/trash-bins', icon: MapPin },
  ]

  return (
    // Wrapper sidebar
    <div className="w-64 h-screen bg-gray-100 border-r border-gray-200 fixed left-0 top-0 flex flex-col">
      {/* Header sidebar */}
      <div className="h-24 flex flex-col justify-center px-5 bg-[#879686] relative overflow-hidden shadow-sm">
        <div className="absolute -right-6 -top-6 w-24 h-24 bg-white/10 rounded-full blur-2xl pointer-events-none"></div>

        <div className="flex items-center justify-between z-10">
          <div className="bg-white/90 p-2 rounded-lg shadow-sm backdrop-blur-sm">
            <img
              src="/eco.png"
              alt="EcoQuest"
              className="h-6 w-auto object-contain"
            />
          </div>

          <div className="h-8 w-[1px] bg-white/30 mx-3"></div>

          <div className="flex flex-col items-start">
            <span className="text-[10px] font-bold tracking-widest text-white/80 uppercase">
              Panel
            </span>
            <span className="text-xs font-black text-white bg-black/20 px-2 py-0.5 rounded tracking-wide shadow-sm">
              ADMIN
            </span>
          </div>
        </div>
      </div>

      {/* Menu utama */}
      <nav className="flex-1 p-4 space-y-2 overflow-y-auto">
        {menuItems.map((item) => {
          const isActive = pathname === item.href
          return (
            <Link
              key={item.href}
              href={item.href}
              // Highlight menu sesuai route aktif
              className={`flex items-center gap-3 px-4 py-3 rounded-xl transition-all duration-200 font-medium ${
                isActive
                  ? 'bg-[#879686] text-white shadow-md'
                  : 'text-gray-500 hover:bg-white hover:text-green-800 hover:shadow-sm'
              }`}
            >
              <item.icon size={20} />
              {item.name}
            </Link>
          )
        })}

        {/* Menu khusus super admin */}
        {userRole === 'super_admin' && (
          <>
            <div className="px-4 mt-6 mb-2 text-xs font-bold text-gray-400 uppercase tracking-wider">
              Super Admin
            </div>
            <Link
              href="/admins"
              className={`flex items-center gap-3 px-4 py-3 rounded-xl transition-all duration-200 font-medium ${
                pathname === '/admins'
                  ? 'bg-purple-100 text-purple-700 shadow-sm'
                  : 'text-gray-500 hover:bg-white hover:text-gray-900 hover:shadow-sm'
              }`}
            >
              <Shield size={20} />
              Kelola Admin
            </Link>
          </>
        )}
      </nav>

      {/* Tombol logout */}
      <div className="p-4 border-t border-gray-200">
        <button
          onClick={handleLogout}
          className="flex items-center gap-3 px-4 py-3 text-red-600 hover:bg-red-50 rounded-xl w-full font-medium transition-all"
        >
          <LogOut size={20} />
          Keluar
        </button>
      </div>
    </div>
  )
}
