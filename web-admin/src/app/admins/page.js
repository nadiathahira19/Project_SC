// src/app/admins/page.js
'use client'

import { useState, useEffect } from 'react'
import { initializeApp, getApps, deleteApp } from 'firebase/app'
import { getAuth, createUserWithEmailAndPassword, signOut } from 'firebase/auth'
import {
  collection,
  getDocs,
  doc,
  setDoc,
  deleteDoc,
  query,
  where,
  serverTimestamp,
} from 'firebase/firestore'

import { useAuth } from '@/lib/AuthContext'
import { useRouter } from 'next/navigation'
import { Shield, Plus, Trash2 } from 'lucide-react'
import { db, firebaseConfig } from '@/lib/firebase'

export default function AdminsPage() {
  const { user, loading: authLoading } = useAuth()
  const router = useRouter()

  const [admins, setAdmins] = useState([])
  const [isModalOpen, setIsModalOpen] = useState(false)
  const [loading, setLoading] = useState(false)
  const [newAdmin, setNewAdmin] = useState({
    name: '',
    email: '',
    password: '',
  })

  // Proteksi akses
  useEffect(() => {
    if (!authLoading && !user) router.push('/login')
  }, [user, authLoading, router])

  // Fetch data admin
  const fetchAdmins = async () => {
    const q = query(
      collection(db, 'users'),
      where('role', 'in', ['admin', 'super_admin'])
    )
    const snapshot = await getDocs(q)
    setAdmins(snapshot.docs.map((d) => ({ id: d.id, ...d.data() })))
  }

  useEffect(() => {
    if (user) fetchAdmins()
  }, [user])

  // Tambah admin
  const handleAddAdmin = async (e) => {
    e.preventDefault()
    setLoading(true)

    const appName = 'SecondaryApp'
    let secondaryApp

    try {
      secondaryApp =
        getApps().find((app) => app.name === appName) ||
        initializeApp(firebaseConfig, appName)

      const secondaryAuth = getAuth(secondaryApp)

      const userCredential = await createUserWithEmailAndPassword(
        secondaryAuth,
        newAdmin.email,
        newAdmin.password
      )

      const created = userCredential.user

      await setDoc(doc(db, 'users', created.uid), {
        uid: created.uid,
        fullName: newAdmin.name,
        email: newAdmin.email,
        role: 'admin',
        createdAt: serverTimestamp(),
        photoUrl: 'https://ui-avatars.com/api/?name=' + newAdmin.name,
      })

      await signOut(secondaryAuth)

      alert('Admin baru berhasil ditambahkan!')
      setIsModalOpen(false)
      setNewAdmin({ name: '', email: '', password: '' })
      fetchAdmins()
    } catch (err) {
      console.error('Gagal tambah admin:', err)
      alert('Gagal: ' + err.message)
    } finally {
      if (secondaryApp) await deleteApp(secondaryApp)
      setLoading(false)
    }
  }

  // Hapus admin
  const handleDelete = async (id) => {
    if (confirm('Hapus akses admin ini?')) {
      await deleteDoc(doc(db, 'users', id))
      fetchAdmins()
    }
  }

  if (authLoading) {
    return <div className="p-8 text-center">Memuat...</div>
  }

  return (
    <div className="p-8 bg-gray-100 min-h-screen">
      <header className="flex justify-between items-center mb-8">
        <div>
          <h1 className="text-2xl font-bold text-gray-800">Kelola Tim Admin</h1>
          <p className="text-gray-500 mt-1">
            Hanya Super Admin yang bisa mengakses halaman ini.
          </p>
        </div>
        <button
          onClick={() => setIsModalOpen(true)}
          className="bg-purple-600 hover:bg-purple-700 text-white px-4 py-2 rounded-xl flex items-center gap-2 font-medium transition-colors shadow-sm"
        >
          <Plus size={20} />
          Admin Baru
        </button>
      </header>

      <div className="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
        <table className="w-full text-left border-collapse">
          <thead>
            <tr className="bg-gray-50 border-b border-gray-100 text-gray-500 text-sm uppercase tracking-wider">
              <th className="p-4 font-medium">Nama</th>
              <th className="p-4 font-medium">Email</th>
              <th className="p-4 font-medium">Role</th>
              <th className="p-4 font-medium text-right">Aksi</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-100">
            {admins.map((admin) => (
              <tr key={admin.id} className="hover:bg-gray-50 transition-colors">
                <td className="p-4 font-medium text-gray-800">
                  {admin.fullName}
                </td>
                <td className="p-4 text-gray-600">{admin.email}</td>
                <td className="p-4">
                  {admin.role === 'super_admin' ? (
                    <span className="bg-purple-100 text-purple-700 px-2 py-1 rounded text-xs font-bold">
                      SUPER ADMIN
                    </span>
                  ) : (
                    <span className="bg-blue-100 text-blue-700 px-2 py-1 rounded text-xs font-bold">
                      ADMIN
                    </span>
                  )}
                </td>
                <td className="p-4 text-right">
                  {admin.role !== 'super_admin' && (
                    <button
                      onClick={() => handleDelete(admin.id)}
                      className="p-2 hover:bg-red-50 text-red-600 rounded-lg"
                    >
                      <Trash2 size={18} />
                    </button>
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {isModalOpen && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="bg-white p-6 rounded-2xl w-full max-w-md shadow-xl">
            <h2 className="text-xl font-bold text-gray-800 mb-4">
              Tambah Admin Baru
            </h2>
            <form onSubmit={handleAddAdmin} className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Nama Lengkap
                </label>
                <input
                  required
                  type="text"
                  className="w-full px-4 py-2 border rounded-lg"
                  value={newAdmin.name}
                  onChange={(e) =>
                    setNewAdmin({ ...newAdmin, name: e.target.value })
                  }
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Email Login
                </label>
                <input
                  required
                  type="email"
                  className="w-full px-4 py-2 border rounded-lg"
                  value={newAdmin.email}
                  onChange={(e) =>
                    setNewAdmin({ ...newAdmin, email: e.target.value })
                  }
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Password
                </label>
                <input
                  required
                  type="password"
                  className="w-full px-4 py-2 border rounded-lg"
                  value={newAdmin.password}
                  onChange={(e) =>
                    setNewAdmin({ ...newAdmin, password: e.target.value })
                  }
                />
              </div>

              <div className="flex justify-end gap-3 mt-6">
                <button
                  type="button"
                  onClick={() => setIsModalOpen(false)}
                  className="px-4 py-2 text-gray-600 hover:bg-gray-100 rounded-lg"
                >
                  Batal
                </button>
                <button
                  type="submit"
                  disabled={loading}
                  className="px-4 py-2 bg-purple-600 hover:bg-purple-700 text-white rounded-lg"
                >
                  {loading ? 'Memproses...' : 'Buat Akun'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  )
}
