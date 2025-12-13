// src/app/users/page.js
'use client'
import { useState, useEffect } from 'react'
import { db } from '@/lib/firebase'
import {
  collection,
  getDocs,
  doc,
  deleteDoc,
  updateDoc,
  addDoc,
  serverTimestamp,
} from 'firebase/firestore'
import { Search, Trash2, Edit, Ban, CheckCircle, Save, X } from 'lucide-react'
import { useAuth } from '@/lib/AuthContext'
import { useRouter } from 'next/navigation'

export default function UsersPage() {
  const { user, loading: authLoading } = useAuth()
  const router = useRouter()

  const [users, setUsers] = useState([])
  const [dataLoading, setDataLoading] = useState(true)

  const [searchTerm, setSearchTerm] = useState('')

  const [isEditModalOpen, setIsEditModalOpen] = useState(false)
  const [editingUser, setEditingUser] = useState(null)

  const [penaltyScore, setPenaltyScore] = useState(0)

  // Proteksi Login
  useEffect(() => {
    if (!authLoading && !user) {
      router.push('/login')
    }
  }, [user, authLoading, router])

  // Fetch Data
  useEffect(() => {
    if (user) {
      const fetchUsers = async () => {
        try {
          const querySnapshot = await getDocs(collection(db, 'users'))
          const usersData = querySnapshot.docs
            .map((doc) => ({
              id: doc.id,
              ...doc.data(),
            }))
            // Filter untuk admin dan super_admin
            .filter((u) => u.role !== 'super_admin' && u.role !== 'admin')

          setUsers(usersData)
        } catch (error) {
          console.error('Error taking users:', error)
        } finally {
          setDataLoading(false)
        }
      }
      fetchUsers()
    }
  }, [user])

  // FUNGSI EDIT
  const openEditModal = (user) => {
    setEditingUser({
      ...user,
      status: user.status || 'active',
    })
    setPenaltyScore(0)
    setIsEditModalOpen(true)
  }

  const handleUpdateUser = async (e) => {
    e.preventDefault()
    try {
      const userRef = doc(db, 'users', editingUser.id)

      // Hitung poin akhir
      const currentPoints = parseInt(editingUser.points) || 0
      const penalty = parseInt(penaltyScore) || 0
      const finalPoints = Math.max(0, currentPoints - penalty)

      // Update Data User Utama
      await updateDoc(userRef, {
        status: editingUser.status,
        points: finalPoints,
      })

      // Catat ke History JIKA ada pinalty
      if (penalty > 0) {
        await addDoc(collection(db, 'users', editingUser.id, 'history'), {
          title: 'Sanksi Pelanggaran', // Penjelasan yang muncul di HP User
          points: -penalty, // Simpan sebagai minus (cth: -50)
          type: 'penalty', // Tipe baru (bukan 'earn')
          createdAt: serverTimestamp(),
          imageUrl: '', // Tidak ada gambar untuk sanksi
        })
      }

      // Update State Lokal
      setUsers(
        users.map((u) =>
          u.id === editingUser.id
            ? {
                ...u,
                status: editingUser.status,
                points: finalPoints,
              }
            : u
        )
      )

      alert(`Berhasil! Poin dikurangi ${penalty}. Sisa poin: ${finalPoints}`)
      setIsEditModalOpen(false)
    } catch (error) {
      console.error('Gagal update:', error)
      alert('Gagal update user.')
    }
  }

  // FUNGSI HAPUS
  const handleDelete = async (userId, userName) => {
    const isConfirmed = window.confirm(
      `Yakin ingin menghapus user "${userName}" PERMANEN?`
    )
    if (isConfirmed) {
      try {
        await deleteDoc(doc(db, 'users', userId))
        setUsers(users.filter((u) => u.id !== userId))
        alert('User dihapus.')
      } catch (error) {
        console.error('Gagal menghapus:', error)
      }
    }
  }

  // LOGIKA SEARCH
  const filteredUsers = users.filter((u) => {
    const name = (u.username || u.displayName || u.fullName || '').toLowerCase()
    const email = (u.email || '').toLowerCase()
    const uid = (u.id || '').toLowerCase()
    const search = searchTerm.toLowerCase()
    return (
      name.includes(search) || email.includes(search) || uid.includes(search)
    )
  })

  // Hitung streak
  const calculateStreak = (user) => {
    if (!user.lastStreakTimestamp || !user.streakCount) return 0
    const lastScan = new Date(user.lastStreakTimestamp.seconds * 1000)
    const now = new Date()
    const today = new Date(now.setHours(0, 0, 0, 0))
    const yesterday = new Date(today)
    yesterday.setDate(yesterday.getDate() - 1)
    const lastScanDate = new Date(lastScan.setHours(0, 0, 0, 0))
    if (lastScanDate >= yesterday) return user.streakCount
    return 0
  }

  if (authLoading)
    return <div className="p-8 text-center">Memuat Authentikasi...</div>
  if (!user) return null

  return (
    <div className="p-8 bg-gray-100 min-h-screen">
      <header className="flex justify-between items-center mb-8">
        <div>
          <h1 className="text-2xl font-bold text-gray-800">Data Pengguna</h1>
          <p className="text-gray-500 mt-1">
            Kelola, pantau, atau blokir pengguna.
          </p>
        </div>

        {/* SEARCH BAR */}
        <div className="relative">
          <input
            type="text"
            placeholder="Cari nama atau email..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="pl-10 pr-4 py-2 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-green-500 w-72"
          />
          <Search className="absolute left-3 top-2.5 text-gray-400" size={18} />
        </div>
      </header>

      <div className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
        {dataLoading ? (
          <div className="p-8 text-center text-gray-500">Mengambil data...</div>
        ) : filteredUsers.length === 0 ? (
          <div className="p-8 text-center text-gray-500">
            {searchTerm ? 'User tidak ditemukan.' : 'Belum ada data user.'}
          </div>
        ) : (
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-gray-50 border-b border-gray-100 text-gray-500 text-sm uppercase tracking-wider">
                <th className="p-4 font-medium">Pengguna</th>
                <th className="p-4 font-medium">Status</th>
                <th className="p-4 font-medium">Poin</th>
                <th className="p-4 font-medium">Streak</th>
                <th className="p-4 font-medium text-right">Aksi</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {filteredUsers.map((u) => (
                <tr
                  key={u.id}
                  className={`hover:bg-gray-50 transition-colors ${
                    u.status === 'banned' ? 'bg-red-50' : ''
                  }`}
                >
                  <td className="p-4">
                    <div className="flex items-center gap-3">
                      <div className="w-10 h-10 rounded-full bg-green-100 border border-green-200 flex items-center justify-center overflow-hidden">
                        {u.photoUrl ? (
                          <img
                            src={u.photoUrl}
                            alt={u.displayName}
                            className="w-full h-full object-cover"
                            onError={(e) => {
                              e.target.style.display = 'none'
                              e.target.nextSibling.style.display = 'block'
                            }}
                          />
                        ) : null}
                        <span
                          className={`font-bold text-green-700 ${
                            u.photoUrl ? 'hidden' : 'block'
                          }`}
                        >
                          {(u.username || u.displayName || 'U')
                            .charAt(0)
                            .toUpperCase()}
                        </span>
                      </div>
                      <div>
                        <p className="font-bold text-gray-800 text-sm">
                          {u.username ||
                            u.displayName ||
                            u.fullName ||
                            'Tanpa Nama'}
                        </p>
                        <p className="text-xs text-gray-500">{u.email}</p>
                      </div>
                    </div>
                  </td>

                  {/* Kolom Status */}
                  <td className="p-4">
                    {u.status === 'banned' ? (
                      <span className="inline-flex items-center gap-1 bg-red-100 text-red-700 px-2 py-1 rounded text-xs font-bold">
                        <Ban size={12} /> BANNED
                      </span>
                    ) : (
                      <span className="inline-flex items-center gap-1 bg-green-100 text-green-700 px-2 py-1 rounded text-xs font-bold">
                        <CheckCircle size={12} /> Active
                      </span>
                    )}
                  </td>

                  <td className="p-4 font-medium text-gray-700">
                    {u.points || 0} Pts
                  </td>
                  <td className="p-4">
                    <div className="flex items-center gap-1 text-orange-500 font-bold text-sm">
                      🔥 {calculateStreak(u)}
                    </div>
                  </td>
                  <td className="p-4 text-right">
                    <div className="flex justify-end gap-2">
                      <button
                        onClick={() => openEditModal(u)}
                        className="p-2 hover:bg-blue-50 text-blue-600 rounded-lg transition-colors"
                        title="Edit / Ban"
                      >
                        <Edit size={18} />
                      </button>
                      <button
                        onClick={() =>
                          handleDelete(u.id, u.username || u.displayName)
                        }
                        className="p-2 hover:bg-red-50 text-red-600 rounded-lg transition-colors"
                        title="Hapus Permanen"
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

      {/* MODAL EDIT USER */}
      {isEditModalOpen && editingUser && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="bg-white p-6 rounded-2xl w-full max-w-md shadow-xl">
            <div className="flex justify-between items-center mb-4">
              <h2 className="text-xl font-bold text-gray-800">Edit User</h2>
              <button
                onClick={() => setIsEditModalOpen(false)}
                className="text-gray-400 hover:text-gray-600"
              >
                <X size={24} />
              </button>
            </div>

            <form onSubmit={handleUpdateUser} className="space-y-4">
              {/* Edit Nama */}
              <div className="bg-slate-50 p-4 rounded-xl border border-slate-100">
                <div className="flex items-center gap-4">
                  {/* Avatar dengan Fallback */}
                  <div className="w-12 h-12 rounded-full bg-green-100 border border-green-200 flex items-center justify-center overflow-hidden shrink-0">
                    {editingUser.photoUrl ? (
                      <img
                        src={editingUser.photoUrl}
                        alt="Avatar"
                        className="w-full h-full object-cover"
                        onError={(e) => {
                          // Jika gambar error (404), sembunyikan <img>
                          e.target.style.display = 'none'
                          // Tampilkan <span> inisial di bawahnya
                          e.target.nextSibling.style.display = 'block'
                        }}
                      />
                    ) : null}

                    <span
                      className={`font-bold text-green-700 text-lg ${
                        editingUser.photoUrl ? 'hidden' : 'block'
                      }`}
                    >
                      {(editingUser.fullName || editingUser.displayName || 'U')
                        .charAt(0)
                        .toUpperCase()}
                    </span>
                  </div>

                  {/* Teks Info */}
                  <div className="overflow-hidden">
                    <p className="text-[10px] text-slate-500 font-bold uppercase tracking-wider mb-0.5">
                      Target User
                    </p>
                    <p className="font-bold text-slate-800 text-lg leading-none truncate">
                      {editingUser.fullName ||
                        editingUser.displayName ||
                        'Tanpa Nama'}
                    </p>
                    <p className="text-xs text-slate-400 mt-1 truncate">
                      {editingUser.email}
                    </p>
                  </div>
                </div>
              </div>

              {/* Edit Poin (Hukuman) */}

              <div className="bg-red-50 p-4 rounded-xl border border-red-100">
                <div className="flex justify-between mb-2">
                  <label className="block text-sm font-bold text-red-800">
                    Berikan Hukuman Poin
                  </label>
                  <span className="text-xs font-medium text-gray-500">
                    Poin Saat Ini:{' '}
                    <span className="text-gray-900 font-bold">
                      {editingUser.points}
                    </span>
                  </span>
                </div>

                <div className="flex gap-2 mb-2">
                  {/* Tombol Cepat */}
                  {[10, 50, 100].map((val) => (
                    <button
                      key={val}
                      type="button"
                      onClick={() => setPenaltyScore(val)}
                      className={`px-3 py-1 text-xs font-bold rounded border ${
                        penaltyScore === val
                          ? 'bg-red-600 text-white border-red-600'
                          : 'bg-white text-red-600 border-red-200 hover:bg-red-50'
                      }`}
                    >
                      -{val}
                    </button>
                  ))}
                  {/* Tombol Reset */}
                  <button
                    type="button"
                    onClick={() => setPenaltyScore(0)}
                    className="px-3 py-1 text-xs font-bold rounded border bg-gray-100 text-gray-600 border-gray-200 hover:bg-gray-200"
                  >
                    Reset
                  </button>
                </div>

                <input
                  type="number"
                  min="0"
                  max={editingUser.points}
                  className="w-full px-4 py-2 border border-red-200 rounded-lg focus:ring-2 focus:ring-red-500 outline-none text-red-700 font-bold"
                  value={penaltyScore}
                  onChange={(e) => setPenaltyScore(Number(e.target.value))}
                  placeholder="Masukkan jumlah pengurangan..."
                />

                <div className="mt-2 text-right text-sm">
                  Sisa Poin:{' '}
                  <span className="font-bold text-gray-900">
                    {Math.max(0, (editingUser.points || 0) - penaltyScore)}
                  </span>
                </div>
              </div>

              {/* Edit Status (Ban/Active) */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Status Akun
                </label>
                <select
                  className={`w-full px-4 py-2 border rounded-lg focus:ring-2 outline-none font-medium ${
                    editingUser.status === 'banned'
                      ? 'border-red-300 text-red-600'
                      : 'border-green-300 text-green-700'
                  }`}
                  value={editingUser.status}
                  onChange={(e) =>
                    setEditingUser({ ...editingUser, status: e.target.value })
                  }
                >
                  <option value="active">Active (Aman)</option>
                  <option value="banned">Banned (Blokir)</option>
                </select>
              </div>

              <div className="flex justify-end gap-3 mt-6">
                <button
                  type="button"
                  onClick={() => setIsEditModalOpen(false)}
                  className="px-4 py-2 text-gray-600 hover:bg-gray-100 rounded-lg font-medium"
                >
                  Batal
                </button>
                <button
                  type="submit"
                  className="px-4 py-2 bg-green-600 hover:bg-green-700 text-white rounded-lg font-medium flex items-center gap-2"
                >
                  <Save size={18} />
                  Simpan Perubahan
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  )
}
