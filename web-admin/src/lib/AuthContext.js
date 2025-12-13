// src/lib/AuthContext.js
'use client'

import { createContext, useContext, useEffect, useState } from 'react'
import { onAuthStateChanged } from 'firebase/auth'
import { auth } from '@/lib/firebase'

// Context untuk state autentikasi global
const AuthContext = createContext({})

// Hook biar akses context lebih simpel
export const useAuth = () => useContext(AuthContext)

export const AuthContextProvider = ({ children }) => {
  const [user, setUser] = useState(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    // Pantau perubahan login/logout user
    const unsubscribe = onAuthStateChanged(auth, (user) => {
      setUser(user || null)
      setLoading(false)
    })

    // Bersihkan listener saat unmount
    return () => unsubscribe()
  }, [])

  return (
    <AuthContext.Provider value={{ user, loading }}>
      {children}
    </AuthContext.Provider>
  )
}
