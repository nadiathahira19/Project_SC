// src/app/scan-history/page.js
'use client'
import { useState, useEffect } from 'react'
import { db } from '@/lib/firebase'
import {
  collectionGroup,
  getDocs,
  query,
  orderBy,
  where,
  limit,
} from 'firebase/firestore'
import { Clock, Image as ImageIcon, User, Copy, Check } from 'lucide-react'
import { useAuth } from '@/lib/AuthContext'
import { useRouter } from 'next/navigation'

export default function ScanHistoryPage() {
  const { user, loading: authLoading } = useAuth()
  const router = useRouter()

  const [history, setHistory] = useState([])
  const [loading, setLoading] = useState(true)
  const [selectedImage, setSelectedImage] = useState(null)
  const [copiedId, setCopiedId] = useState(null)

  // Proteksi Halaman
  useEffect(() => {
    if (!authLoading && !user) router.push('/login')
  }, [user, authLoading, router])

  // Ambil Data History dari SEMUA User
  const fetchHistory = async () => {
    setLoading(true)
    try {
      const historyQuery = query(
        collectionGroup(db, 'history'),
        where('type', '==', 'earn'), // Hanya ambil yang 'dapat poin' (bukan redeem)
        orderBy('createdAt', 'desc'), // Urutkan dari yang terbaru
        limit(50) // Batasi 50 terakhir
      )

      const querySnapshot = await getDocs(historyQuery)

      const data = querySnapshot.docs.map((doc) => ({
        id: doc.id,
        userId: doc.ref.parent.parent ? doc.ref.parent.parent.id : 'Unknown',
        ...doc.data(),
      }))

      setHistory(data)
    } catch (error) {
      console.error('Error fetching history:', error)
    } finally {
      setLoading(false)
    }
  }

  const handleCopyUid = (uid) => {
    navigator.clipboard.writeText(uid)
    setCopiedId(uid)
    setTimeout(() => setCopiedId(null), 2000) // Reset setelah 2 detik
  }

  useEffect(() => {
    if (user) fetchHistory()
  }, [user])

  if (authLoading) return <div className="p-8 text-center">Memuat...</div>
  if (!user) return null

  return (
    <div className="p-8 bg-gray-100 min-h-screen">
      <header className="mb-8">
        <h1 className="text-2xl font-bold text-gray-800">
          Monitoring Scan Sampah
        </h1>
        <p className="text-gray-500 mt-1">
          Pantau aktivitas pembuangan sampah pengguna secara real-time.
        </p>
      </header>

      <div className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
        {loading ? (
          <div className="p-8 text-center text-gray-500">Mengambil data...</div>
        ) : history.length === 0 ? (
          <div className="p-12 text-center flex flex-col items-center text-gray-500">
            <Clock size={48} className="mb-4 text-gray-300" />
            <p>Belum ada aktivitas scan sampah.</p>
          </div>
        ) : (
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-gray-50 border-b border-gray-100 text-gray-500 text-sm uppercase tracking-wider">
                <th className="p-4 font-medium">Waktu</th>
                <th className="p-4 font-medium">Aktivitas</th>
                <th className="p-4 font-medium">User UID</th>
                <th className="p-4 font-medium">Poin</th>
                <th className="p-4 font-medium text-right">Bukti Foto</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {history.map((item) => (
                <tr
                  key={item.id}
                  className="hover:bg-gray-50 transition-colors"
                >
                  <td className="p-4 text-sm text-gray-600">
                    {item.createdAt?.seconds
                      ? new Date(item.createdAt.seconds * 1000).toLocaleString(
                          'id-ID'
                        )
                      : '-'}
                  </td>
                  <td className="p-4">
                    <span className="font-medium text-gray-800">
                      {item.title || 'Scan Sampah'}
                    </span>
                  </td>
                  <td className="p-4">
                    <div className="flex items-center gap-2">
                      <span className="text-xs font-mono text-gray-500 bg-gray-100 px-2 py-1 rounded">
                        {item.userId.substring(0, 8)}...
                      </span>

                      {/* Tombol Copy */}
                      <button
                        onClick={() => handleCopyUid(item.userId)}
                        className="text-gray-400 hover:text-blue-600 transition-colors"
                        title="Copy Full UID"
                      >
                        {copiedId === item.userId ? (
                          <Check size={14} className="text-green-600" />
                        ) : (
                          <Copy size={14} />
                        )}
                      </button>
                    </div>
                  </td>
                  <td className="p-4">
                    <span className="bg-green-100 text-green-700 px-2 py-1 rounded text-xs font-bold">
                      +{item.points}
                    </span>
                  </td>
                  <td className="p-4 text-right">
                    {item.imageUrl ? (
                      <button
                        onClick={() => setSelectedImage(item.imageUrl)}
                        className="inline-flex items-center gap-1 text-blue-600 hover:underline text-sm"
                      >
                        <ImageIcon size={16} /> Lihat
                      </button>
                    ) : (
                      <span className="text-gray-400 text-xs">No Image</span>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>

      {/* MODAL PREVIEW BUKTI */}
      {selectedImage && (
        <div
          className="fixed inset-0 bg-black/90 z-50 flex items-center justify-center p-4 backdrop-blur-sm"
          onClick={() => setSelectedImage(null)}
        >
          <div className="relative max-w-3xl w-full flex flex-col items-center">
            {/* Container Gambar dengan background default loading */}
            <div className="relative w-full bg-slate-800 rounded-xl overflow-hidden shadow-2xl border border-slate-700">
              <img
                src={selectedImage.replace('http://', 'https://')}
                alt="Bukti Sampah"
                className="w-full h-full object-contain max-h-[80vh] bg-black"
                onError={(e) => {
                  e.target.onerror = null
                  e.target.src =
                    'https://placehold.co/600x400/1e293b/cbd5e1?text=Gambar+Tidak+Ditemukan'
                }}
              />
            </div>

            <p className="text-slate-400 text-center mt-6 text-sm font-medium cursor-pointer hover:text-white transition-colors">
              Klik di mana saja untuk menutup
            </p>
          </div>
        </div>
      )}
    </div>
  )
}
