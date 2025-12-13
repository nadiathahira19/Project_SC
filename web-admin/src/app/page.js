// src/app/page.js
'use client'

import { useState, useEffect } from 'react'
import { db } from '@/lib/firebase'
import {
  collection,
  getDocs,
  collectionGroup,
  query,
  where,
} from 'firebase/firestore'
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
} from 'recharts'
import { Users, Trophy, Trash } from 'lucide-react'
import { useAuth } from '@/lib/AuthContext'
import { useRouter } from 'next/navigation'

export default function Dashboard() {
  const { user, loading: authLoading } = useAuth()
  const router = useRouter()

  const [stats, setStats] = useState({
    totalUsers: 0,
    totalPointsEarned: 0,
    totalRewardsItems: 0,
  })

  // Data grafik 7 hari
  const [chartData, setChartData] = useState([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    // Redirect jika belum login
    if (!authLoading && !user) router.push('/login')
  }, [user, authLoading, router])

  useEffect(() => {
    const fetchStats = async () => {
      try {
        // Ambil semua user
        const usersSnapshot = await getDocs(collection(db, 'users'))

        // Filter user asli (bukan admin)
        const realUsers = usersSnapshot.docs.filter((doc) => {
          const d = doc.data()
          return d.role !== 'super_admin' && d.role !== 'admin'
        })
        const totalUsers = realUsers.length

        // Query riwayat earn poin
        const historyQuery = query(
          collectionGroup(db, 'history'),
          where('type', '==', 'earn')
        )
        const historySnapshot = await getDocs(historyQuery)

        let totalPoints = 0

        // Siapkan slot untuk 7 hari terakhir
        const today = new Date()
        const last7Days = []

        for (let i = 6; i >= 0; i--) {
          const d = new Date()
          d.setDate(today.getDate() - i)
          d.setHours(0, 0, 0, 0)
          const dayName = d.toLocaleDateString('id-ID', { weekday: 'short' })

          last7Days.push({
            dateObj: d,
            name: dayName,
            sampah: 0,
            user: 0,
          })
        }

        // Hitung poin sampah ke masing-masing slot hari
        historySnapshot.forEach((doc) => {
          const data = doc.data()
          totalPoints += data.points || 0

          if (data.createdAt) {
            const docDate = data.createdAt.toDate()
            docDate.setHours(0, 0, 0, 0)

            const foundDay = last7Days.find(
              (d) => d.dateObj.getTime() === docDate.getTime()
            )
            if (foundDay) foundDay.sampah += data.points || 0
          }
        })

        // Hitung user baru per hari
        realUsers.forEach((doc) => {
          const data = doc.data()
          if (data.createdAt) {
            const docDate = data.createdAt.toDate()
            docDate.setHours(0, 0, 0, 0)

            const foundDay = last7Days.find(
              (d) => d.dateObj.getTime() === docDate.getTime()
            )
            if (foundDay) foundDay.user += 1
          }
        })

        // Total item reward
        const rewardsSnapshot = await getDocs(collection(db, 'rewards'))
        const totalRewardsItems = rewardsSnapshot.size

        // Update state
        setStats({
          totalUsers,
          totalPointsEarned: totalPoints,
          totalRewardsItems,
        })

        setChartData(last7Days)
      } catch (error) {
        console.error('Error fetching dashboard stats:', error)
      } finally {
        setLoading(false)
      }
    }

    // Hanya fetch jika user sudah siap
    if (user) fetchStats()
  }, [user])

  // Loading awal
  if (authLoading || loading)
    return (
      <div className="flex items-center justify-center min-h-screen bg-gray-100 text-gray-500">
        Memuat Statistik...
      </div>
    )

  if (!user) return null

  return (
    <div className="min-h-screen">
      {/* Header Dashboard */}
      <div className="bg-[#879686] pt-10 pb-24 px-8 rounded-b-[3rem] shadow-sm relative overflow-hidden">
        <div className="absolute top-0 right-0 w-64 h-64 bg-white/10 rounded-full blur-3xl pointer-events-none translate-x-1/3 -translate-y-1/2"></div>

        <header className="flex justify-between items-end relative z-10">
          <div>
            <h2 className="text-3xl font-bold text-white tracking-tight">
              Dashboard
            </h2>
            <p className="text-green-50 mt-1 text-sm opacity-90">
              Ringkasan performa ekosistem EcoQuest.
            </p>
          </div>

          {/* Badge akun */}
          <div className="flex items-center gap-3 bg-white/20 backdrop-blur-md px-4 py-2 rounded-2xl border border-white/30 shadow-sm">
            <div className="w-9 h-9 rounded-xl bg-white text-[#98A999] flex items-center justify-center font-black text-lg uppercase shadow-sm">
              {user.email ? user.email.charAt(0) : 'A'}
            </div>
            <div className="flex flex-col">
              <span className="text-xs text-green-100 font-medium uppercase tracking-wider">
                Role
              </span>
              <span className="text-sm font-bold text-white leading-none">
                {user.email ? user.email.split('@')[0] : 'Admin'}
              </span>
            </div>
          </div>
        </header>
      </div>

      {/* Konten utama */}
      <div className="px-8 -mt-16 pb-12 relative z-20">
        {/* Kartu ringkasan */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
          <StatCard
            icon={Users}
            title="Total Pengguna"
            value={stats.totalUsers}
            color="blue"
          />
          <StatCard
            icon={Trash}
            title="Total Poin Sampah"
            value={stats.totalPointsEarned.toLocaleString('id-ID')}
            color="green"
          />
          <StatCard
            icon={Trophy}
            title="Reward Tersedia"
            value={stats.totalRewardsItems}
            color="yellow"
          />
        </div>

        {/* Grafik 7 hari */}
        <div className="bg-white p-8 rounded-3xl shadow-xl shadow-gray-200/50 border border-gray-100">
          <div className="flex items-center justify-between mb-8">
            <div>
              <h3 className="font-bold text-gray-800 text-xl">
                Tren Aktivitas
              </h3>
              <p className="text-gray-400 text-sm">Data 7 hari terakhir</p>
            </div>

            {/* Legend */}
            <div className="flex gap-4 text-sm">
              <div className="flex items-center gap-2">
                <div className="w-3 h-3 rounded-full bg-[#22c55e]"></div>
                <span className="text-gray-600">Poin Sampah</span>
              </div>
              <div className="flex items-center gap-2">
                <div className="w-3 h-3 rounded-full bg-[#3b82f6]"></div>
                <span className="text-gray-600">User Baru</span>
              </div>
            </div>
          </div>

          <div className="h-80">
            {/* Tampilkan empty state jika grafik kosong */}
            {chartData.every((d) => d.sampah === 0 && d.user === 0) ? (
              <div className="h-full flex items-center justify-center text-gray-400 bg-gray-50 rounded-2xl border border-dashed border-gray-200 flex-col">
                <Trash size={32} className="mb-2 opacity-20" />
                <p>Belum ada aktivitas minggu ini.</p>
              </div>
            ) : (
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={chartData} barGap={8}>
                  <CartesianGrid
                    strokeDasharray="3 3"
                    vertical={false}
                    stroke="#f1f5f9"
                  />
                  <XAxis
                    dataKey="name"
                    axisLine={false}
                    tickLine={false}
                    tick={{ fill: '#94a3b8', fontSize: 12 }}
                    dy={10}
                  />
                  <YAxis
                    axisLine={false}
                    tickLine={false}
                    tick={{ fill: '#94a3b8', fontSize: 12 }}
                  />
                  <Tooltip
                    contentStyle={{
                      borderRadius: '16px',
                      border: 'none',
                      boxShadow: '0 10px 40px rgba(0,0,0,0.1)',
                    }}
                    cursor={{ fill: '#f8fafc' }}
                  />
                  <Bar
                    dataKey="sampah"
                    name="Poin Sampah"
                    fill="#22c55e"
                    radius={[6, 6, 0, 0]}
                    barSize={24}
                  />
                  <Bar
                    dataKey="user"
                    name="User Baru"
                    fill="#3b82f6"
                    radius={[6, 6, 0, 0]}
                    barSize={24}
                  />
                </BarChart>
              </ResponsiveContainer>
            )}
          </div>
        </div>
      </div>
    </div>
  )
}

// Kartu statistik kecil
function StatCard({ icon: Icon, title, value, color }) {
  const colors = {
    blue: 'bg-blue-50 text-blue-600',
    green: 'bg-green-50 text-green-600',
    yellow: 'bg-yellow-50 text-yellow-600',
  }

  return (
    <div className="bg-white p-6 rounded-3xl shadow-lg shadow-gray-200/50 border border-gray-100 flex items-center gap-5 transition-all duration-300 hover:-translate-y-1 hover:shadow-xl">
      <div className={`p-4 rounded-2xl ${colors[color]}`}>
        <Icon size={30} strokeWidth={2.5} />
      </div>
      <div>
        <p className="text-gray-400 text-xs font-bold uppercase tracking-wider mb-1">
          {title}
        </p>
        <h3 className="text-3xl font-extrabold text-gray-800">{value}</h3>
      </div>
    </div>
  )
}
