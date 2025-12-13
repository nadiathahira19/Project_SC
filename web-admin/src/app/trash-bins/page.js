// src/app/trash-bins/page.js
'use client'
import { useState, useEffect } from 'react'
import { db } from '@/lib/firebase'
// Kita import GeoPoint untuk simpan lokasi
import {
  collection,
  getDocs,
  addDoc,
  deleteDoc,
  doc,
  GeoPoint,
} from 'firebase/firestore'
import { Trash2, Plus, MapPin } from 'lucide-react'
import { useAuth } from '@/lib/AuthContext'
import { useRouter } from 'next/navigation'

export default function TrashBinsPage() {
  const { user, loading: authLoading } = useAuth()
  const router = useRouter()

  const [bins, setBins] = useState([])
  const [loading, setLoading] = useState(true)
  const [isModalOpen, setIsModalOpen] = useState(false)

  // State Form Tambah
  const [newBin, setNewBin] = useState({
    name: '',
    binId: '',
    lat: '',
    lng: '',
  })

  // Proteksi Halaman
  useEffect(() => {
    if (!authLoading && !user) router.push('/login')
  }, [user, authLoading, router])

  // Ambil Data Tong Sampah
  const fetchBins = async () => {
    try {
      const querySnapshot = await getDocs(collection(db, 'trash_bins'))
      const binsData = querySnapshot.docs.map((doc) => {
        const data = doc.data()
        return {
          id: doc.id,
          ...data,
          lat: data.location ? data.location.latitude : 0,
          lng: data.location ? data.location.longitude : 0,
        }
      })
      setBins(binsData)
    } catch (error) {
      console.error('Error fetching bins:', error)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    if (user) fetchBins()
  }, [user])

  // Fungsi Tambah Tong Sampah
  const handleAddBin = async (e) => {
    e.preventDefault()
    try {
      // Validasi input lat/lng
      const lat = parseFloat(newBin.lat)
      const lng = parseFloat(newBin.lng)

      if (isNaN(lat) || isNaN(lng)) {
        alert('Latitude dan Longitude harus angka!')
        return
      }

      await addDoc(collection(db, 'trash_bins'), {
        name: newBin.name,
        binId: newBin.binId || `BIN-${Date.now()}`, // Auto ID kalau kosong
        location: new GeoPoint(lat, lng),
      })

      alert('Tong sampah berhasil ditambahkan!')
      setIsModalOpen(false)
      setNewBin({ name: '', binId: '', lat: '', lng: '' })
      fetchBins()
    } catch (error) {
      console.error('Gagal menambah:', error)
      alert('Gagal menambah tong sampah.')
    }
  }

  // Fungsi Hapus
  const handleDelete = async (id, name) => {
    if (confirm(`Hapus lokasi "${name}"?`)) {
      try {
        await deleteDoc(doc(db, 'trash_bins', id))
        setBins(bins.filter((b) => b.id !== id))
      } catch (error) {
        console.error('Gagal menghapus:', error)
      }
    }
  }

  if (authLoading) return <div className="p-8 text-center">Memuat...</div>
  if (!user) return null

  return (
    <div className="p-8 bg-gray-100 min-h-screen">
      <header className="flex justify-between items-center mb-8">
        <div>
          <h1 className="text-2xl font-bold text-gray-800">
            Kelola Tong Sampah
          </h1>
          <p className="text-gray-500 mt-1">
            Atur titik lokasi pembuangan sampah.
          </p>
        </div>

        <button
          onClick={() => setIsModalOpen(true)}
          className="bg-green-600 hover:bg-green-700 text-white px-4 py-2 rounded-xl flex items-center gap-2 font-medium transition-colors shadow-sm"
        >
          <Plus size={20} />
          Tambah Lokasi
        </button>
      </header>

      {/* Tabel */}
      <div className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
        {loading ? (
          <div className="p-8 text-center text-gray-500">Mengambil data...</div>
        ) : bins.length === 0 ? (
          <div className="p-12 text-center flex flex-col items-center text-gray-500">
            <MapPin size={48} className="mb-4 text-gray-300" />
            <p>Belum ada lokasi tong sampah.</p>
          </div>
        ) : (
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-gray-50 border-b border-gray-100 text-gray-500 text-sm uppercase tracking-wider">
                <th className="p-4 font-medium">ID Bin</th>
                <th className="p-4 font-medium">Nama Lokasi</th>
                <th className="p-4 font-medium">Koordinat</th>
                <th className="p-4 font-medium text-right">Aksi</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {bins.map((b) => (
                <tr key={b.id} className="hover:bg-gray-50 transition-colors">
                  <td className="p-4 text-sm font-mono text-gray-600">
                    {b.binId}
                  </td>
                  <td className="p-4 font-medium text-gray-800">{b.name}</td>
                  <td className="p-4 text-sm text-gray-600">
                    <div className="flex flex-col">
                      <span>Lat: {b.lat}</span>
                      <span>Long: {b.lng}</span>
                    </div>
                  </td>
                  <td className="p-4 text-right">
                    <button
                      onClick={() => handleDelete(b.id, b.name)}
                      className="p-2 hover:bg-red-50 text-red-600 rounded-lg transition-colors"
                    >
                      <Trash2 size={18} />
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>

      {/* MODAL TAMBAH */}
      {isModalOpen && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="bg-white p-6 rounded-2xl w-full max-w-md shadow-xl">
            <h2 className="text-xl font-bold text-gray-800 mb-4">
              Tambah Lokasi Baru
            </h2>
            <form onSubmit={handleAddBin} className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Nama Lokasi
                </label>
                <input
                  required
                  type="text"
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 outline-none"
                  value={newBin.name}
                  onChange={(e) =>
                    setNewBin({ ...newBin, name: e.target.value })
                  }
                  placeholder="Contoh: Taman Kota"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  ID Bin (Opsional)
                </label>
                <input
                  type="text"
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 outline-none"
                  value={newBin.binId}
                  onChange={(e) =>
                    setNewBin({ ...newBin, binId: e.target.value })
                  }
                  placeholder="Contoh: BIN-001 (Kosongkan utk auto)"
                />
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Latitude
                  </label>
                  <input
                    required
                    type="text"
                    className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 outline-none"
                    value={newBin.lat}
                    onChange={(e) =>
                      setNewBin({ ...newBin, lat: e.target.value })
                    }
                    placeholder="-6.200000"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Longitude
                  </label>
                  <input
                    required
                    type="text"
                    className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 outline-none"
                    value={newBin.lng}
                    onChange={(e) =>
                      setNewBin({ ...newBin, lng: e.target.value })
                    }
                    placeholder="106.816666"
                  />
                </div>
              </div>

              <div className="flex justify-end gap-3 mt-6">
                <button
                  type="button"
                  onClick={() => setIsModalOpen(false)}
                  className="px-4 py-2 text-gray-600 hover:bg-gray-100 rounded-lg font-medium"
                >
                  Batal
                </button>
                <button
                  type="submit"
                  className="px-4 py-2 bg-green-600 hover:bg-green-700 text-white rounded-lg font-medium"
                >
                  Simpan
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  )
}
