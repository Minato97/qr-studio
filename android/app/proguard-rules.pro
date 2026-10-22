# R8 elimina la implementacion generada de Room usada por WorkManager (google_mobile_ads)
-keep class androidx.work.impl.WorkDatabase_Impl { *; }
-keep class * extends androidx.room.RoomDatabase { *; }
-keep class androidx.work.** { *; }
