// src/app/rewards/page.js
'use client'

import { useState, useEffect } from 'react'
import { db } from '@/lib/firebase'

// Firestore ops
import {
  collection,
  getDocs,
  addDoc,
  deleteDoc,
  updateDoc,
  doc,
  serverTimestamp,
} from 'firebase/firestore'

// UI & util
import { Search, Trash2, Plus, Gift, Edit } from 'lucide-react'
import { useAuth } from '@/lib/AuthContext'
import { useRouter } from 'next/navigation'

export default function RewardsPage() {
  const { user, loading: authLoading } = useAuth()
  const router = useRouter()

  const [rewards, setRewards] = useState([])
  const [loading, setLoading] = useState(true)
  const [isModalOpen, setIsModalOpen] = useState(false)

  // Mode edit, null = tambah baru
  const [editingId, setEditingId] = useState(null)

  // Data form untuk tambah/edit reward
  const [formData, setFormData] = useState({
    title: '',
    points: '',
    stock: '',
    description: '',
  })

  // Proteksi halaman
  useEffect(() => {
    if (!authLoading && !user) router.push('/login')
  }, [user, authLoading, router])

  // Ambil data reward
  const fetchRewards = async () => {
    try {
      const snap = await getDocs(collection(db, 'rewards'))
      setRewards(snap.docs.map((d) => ({ id: d.id, ...d.data() })))
    } catch (error) {
      console.error('Error fetching rewards:', error)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    if (user) fetchRewards()
  }, [user])

  // Buka modal untuk tambah baru
  const openAddModal = () => {
    setEditingId(null)
    setFormData({ title: '', points: '', stock: '', description: '' })
    setIsModalOpen(true)
  }

  // Buka modal untuk edit data
  const openEditModal = (reward) => {
    setEditingId(reward.id)
    setFormData({
      title: reward.title,
      points: reward.points,
      stock: reward.stock,
      description: reward.description || '',
    })
    setIsModalOpen(true)
  }

  // Simpan data (tambah atau edit)
  const handleSave = async (e) => {
    e.preventDefault()

    const payload = {
      title: formData.title,
      points: Number(formData.points),
      stock: Number(formData.stock),
      description: formData.description,
      // Placeholder default
      imageUrl: 'https://cdn-icons-png.flaticon.com/512/4213/4213958.png',
    }

    try {
      if (editingId) {
        // Update data
        await updateDoc(doc(db, 'rewards', editingId), payload)
        alert('Data hadiah berhasil diperbarui!')
      } else {
        // Tambah baru
        await addDoc(collection(db, 'rewards'), {
          ...payload,
          createdAt: serverTimestamp(),
        })
        alert('Hadiah baru berhasil ditambahkan!')
      }

      setIsModalOpen(false)
      fetchRewards()
    } catch (error) {
      console.error('Gagal menyimpan:', error)
      alert('Gagal menyimpan data.')
    }
  }

  // Hapus data reward
  const handleDelete = async (id, title) => {
    if (confirm(`Hapus hadiah "${title}"?`)) {
      try {
        await deleteDoc(doc(db, 'rewards', id))
        setRewards(rewards.filter((r) => r.id !== id))
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
          <h1 className="text-2xl font-bold text-gray-800">Kelola Reward</h1>
          <p className="text-gray-500 mt-1">Atur stok dan harga poin hadiah.</p>
        </div>

        <button
          onClick={openAddModal}
          className="bg-green-600 hover:bg-green-700 text-white px-4 py-2 rounded-xl flex items-center gap-2 font-medium transition-colors shadow-sm"
        >
          <Plus size={20} />
          Tambah Hadiah
        </button>
      </header>

      <div className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
        {loading ? (
          <div className="p-8 text-center text-gray-500">Mengambil data...</div>
        ) : rewards.length === 0 ? (
          <div className="p-12 text-center flex flex-col items-center text-gray-500">
            <Gift size={48} className="mb-4 text-gray-300" />
            <p>Belum ada hadiah tersedia.</p>
          </div>
        ) : (
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-gray-50 border-b border-gray-100 text-gray-500 text-sm uppercase tracking-wider">
                <th className="p-4 font-medium">Nama Hadiah</th>
                <th className="p-4 font-medium">Poin Dibutuhkan</th>
                <th className="p-4 font-medium">Stok</th>
                <th className="p-4 font-medium text-right">Aksi</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {rewards.map((r) => (
                <tr key={r.id} className="hover:bg-gray-50 transition-colors">
                  <td className="p-4 font-medium text-gray-800">
                    {r.title}
                    <p className="text-xs text-gray-400 font-normal mt-0.5">
                      {r.description}
                    </p>
                  </td>

                  <td className="p-4 text-green-600 font-bold">
                    {r.points} Pts
                  </td>

                  <td className="p-4">
                    <span
                      className={`px-2 py-1 rounded text-xs font-bold ${
                        r.stock > 0
                          ? 'bg-blue-100 text-blue-700'
                          : 'bg-red-100 text-red-700'
                      }`}
                    >
                      {r.stock > 0 ? `${r.stock} Tersedia` : 'Habis'}
                    </span>
                  </td>

                  <td className="p-4 text-right">
                    <div className="flex justify-end gap-2">
                      <button
                        onClick={() => openEditModal(r)}
                        className="p-2 hover:bg-blue-50 text-blue-600 rounded-lg transition-colors"
                        title="Edit / Restock"
                      >
                        <Edit size={18} />
                      </button>

                      <button
                        onClick={() => handleDelete(r.id, r.title)}
                        className="p-2 hover:bg-red-50 text-red-600 rounded-lg transition-colors"
                        title="Hapus"
                      >
                        <Trash2 size={18} />
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>

      {isModalOpen && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="bg-white p-6 rounded-2xl w-full max-w-md shadow-xl">
            <h2 className="text-xl font-bold text-gray-800 mb-4">
              {editingId ? 'Edit Hadiah' : 'Tambah Hadiah Baru'}
            </h2>

            <form onSubmit={handleSave} className="space-y-4">
              {/* Form input tetap sama, tidak disentuh */}
              ...
            </form>
          </div>
        </div>
      )}
    </div>
  )
}
