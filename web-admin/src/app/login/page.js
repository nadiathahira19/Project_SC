// src/app/login/page.js
'use client'
import { useState } from 'react'
import { signInWithEmailAndPassword } from 'firebase/auth'
import { auth } from '@/lib/firebase'
import { useRouter } from 'next/navigation'
import { Mail, Lock, Loader2, ArrowRight } from 'lucide-react'

export default function LoginPage() {
  // State dasar login
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)

  const router = useRouter()

  // Fungsi login ke Firebase
  const handleLogin = async (e) => {
    e.preventDefault()
    setLoading(true)
    setError('')

    try {
      await signInWithEmailAndPassword(auth, email, password)
      router.push('/') // Redirect admin setelah login
    } catch (err) {
      console.error(err)
      setError('Email atau password tidak valid.')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen w-full flex bg-white">
      {/* Bagian kiri hanya muncul di desktop */}
      <div className="hidden lg:flex w-1/2 relative bg-gray-900 overflow-hidden">
        <img
          src="https://images.unsplash.com/photo-1542601906990-b4d3fb778b09?q=80&w=2813&auto=format&fit=crop"
          alt="Nature Background"
          className="absolute inset-0 w-full h-full object-cover opacity-80"
        />
        <div className="absolute inset-0 bg-gradient-to-t from-black/80 via-black/20 to-transparent"></div>

        <div className="relative z-10 p-16 flex flex-col justify-between h-full text-white">
          {/* Logo + identitas panel admin */}
          <div className="flex items-center gap-3">
            <img
              src="/eco.png"
              alt="EcoQuest"
              className="h-8 w-auto brightness-0 invert"
            />
            <span className="font-bold tracking-widest text-sm opacity-80">
              ADMIN PANEL
            </span>
          </div>

          {/* Copywriting halaman login */}
          <div>
            <h2 className="text-4xl font-extrabold leading-tight mb-4">
              Manage Waste,
              <br /> Create Value.
            </h2>
            <p className="text-gray-300 text-lg max-w-md leading-relaxed">
              Selamat datang kembali, Admin. Pantau aktivitas daur ulang dan
              kelola ekosistem EcoQuest dalam satu dashboard.
            </p>
          </div>

          <div className="text-xs text-gray-500">© 2025 EcoQuest Inc.</div>
        </div>
      </div>

      {/* Bagian kanan berisi form login */}
      <div className="w-full lg:w-1/2 flex items-center justify-center p-8 md:p-16 bg-gray-200">
        <div className="w-full max-w-md space-y-8">
          {/* Logo khusus tampilan mobile */}
          <div className="lg:hidden mb-8 text-center">
            <img
              src="/eco.png"
              alt="EcoQuest"
              className="h-10 w-auto mx-auto mb-4"
            />
          </div>

          <div className="text-center lg:text-left">
            <h1 className="text-3xl font-bold text-gray-900 tracking-tight">
              Masuk Akun
            </h1>
            <p className="text-gray-500 mt-2">
              Silakan masukkan kredensial admin Anda.
            </p>
          </div>

          {/* Form login */}
          <form onSubmit={handleLogin} className="space-y-6">
            {/* Error feedback */}
            {error && (
              <div className="p-4 rounded-xl bg-red-50 border border-red-100 text-red-600 text-sm font-medium flex items-center gap-2 animate-pulse">
                <div className="w-1.5 h-1.5 rounded-full bg-red-500"></div>
                {error}
              </div>
            )}

            <div className="space-y-5">
              {/* Input email */}
              <div className="group">
                <label className="block text-sm font-medium text-gray-700 mb-1.5 ml-1">
                  Email Address
                </label>
                <div className="relative">
                  <div className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-400 group-focus-within:text-[#98A999] transition-colors">
                    <Mail size={20} />
                  </div>
                  <input
                    type="email"
                    required
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    className="w-full pl-12 pr-4 py-3.5 bg-gray-50 border border-gray-200 rounded-2xl focus:bg-white focus:ring-4 focus:ring-[#98A999]/20 focus:border-[#98A999] outline-none transition-all text-gray-800"
                    placeholder="admin@ecoquest.com"
                  />
                </div>
              </div>

              {/* Input password */}
              <div className="group">
                <label className="block text-sm font-medium text-gray-700 mb-1.5 ml-1">
                  Password
                </label>
                <div className="relative">
                  <div className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-400 group-focus-within:text-[#98A999] transition-colors">
                    <Lock size={20} />
                  </div>
                  <input
                    type="password"
                    required
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    className="w-full pl-12 pr-4 py-3.5 bg-gray-50 border border-gray-200 rounded-2xl focus:bg-white focus:ring-4 focus:ring-[#98A999]/20 focus:border-[#98A999] outline-none transition-all text-gray-800"
                    placeholder="••••••••"
                  />
                </div>
              </div>
            </div>

            {/* Tombol login */}
            <button
              type="submit"
              disabled={loading}
              className="w-full bg-gray-900 hover:bg-gray-800 text-white font-bold py-4 rounded-2xl transition-all active:scale-[0.98] shadow-xl hover:shadow-2xl flex items-center justify-center gap-2 disabled:opacity-70"
            >
              {loading ? (
                <Loader2 size={20} className="animate-spin" />
              ) : (
                <>
                  Masuk Dashboard <ArrowRight size={20} />
                </>
              )}
            </button>
          </form>
        </div>
      </div>
    </div>
  )
}
