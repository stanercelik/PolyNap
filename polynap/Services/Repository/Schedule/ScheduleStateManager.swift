import Foundation
import SwiftData
import OSLog

/// Schedule aktivasyon/deaktivasyon işlemleri için service
@MainActor
final class ScheduleStateManager: BaseRepository {
    
    static let shared = ScheduleStateManager()
    
    private override init() {
        super.init()
        logger.debug("🎯 ScheduleStateManager başlatıldı")
    }
    
    // MARK: - Schedule State Management
    
    /// Tüm programları deaktive eder
    func deactivateAllSchedules() async throws {
        // ScheduleEntity'leri deaktive et
        let scheduleDescriptor = FetchDescriptor<ScheduleEntity>(
            predicate: #Predicate<ScheduleEntity> { $0.isActive == true && $0.isDeleted == false }
        )
        
        // UserSchedule'ları da deaktive et
        let userScheduleDescriptor = FetchDescriptor<UserSchedule>(
            predicate: #Predicate<UserSchedule> { $0.isActive == true }
        )
        
        do {
            let activeSchedules = try fetch(scheduleDescriptor)
            let activeUserSchedules = try fetch(userScheduleDescriptor)
            
            if activeSchedules.isEmpty && activeUserSchedules.isEmpty {
                logger.debug("ℹ️ Deaktive edilecek aktif program bulunamadı.")
                return
            }
            
            logger.debug("🗂️ \(activeSchedules.count) ScheduleEntity ve \(activeUserSchedules.count) UserSchedule deaktive ediliyor")
            
            for schedule in activeSchedules {
                schedule.isActive = false
                schedule.updatedAt = Date()
            }
            
            for userSchedule in activeUserSchedules {
                userSchedule.isActive = false
                userSchedule.updatedAt = Date()
            }
            
            try save()
            logger.debug("✅ Tüm programlar başarıyla deaktive edildi")
        } catch {
            logger.error("❌ Programlar deaktive edilirken hata: \(error.localizedDescription)")
            throw RepositoryError.updateFailed
        }
    }
    
    /// Belirli bir programı aktif veya pasif yapar
    func setScheduleActive(id: String, isActive: Bool) async throws {
        guard let uuid = UUID(uuidString: id) else {
            logger.error("❌ Geçersiz UUID formatı: \(id)")
            throw RepositoryError.invalidData
        }
        
        // 1. Eğer bir programı aktif yapıyorsak, önce diğer tüm aktif programları pasifleştir
        if isActive {
            logger.debug("🗂️ Program (ID: \(uuid.uuidString)) aktif ediliyor, diğerleri pasifleştirilecek.")
            try await deactivateOtherSchedules(exceptId: uuid)
        }

        // 2. Hedef ScheduleEntity'i güncelle
        let scheduleEntityDescriptor = FetchDescriptor<ScheduleEntity>(
            predicate: #Predicate<ScheduleEntity> { $0.id == uuid && $0.isDeleted == false }
        )
        
        do {
            guard let scheduleEntityToUpdate = try fetch(scheduleEntityDescriptor).first else {
                logger.error("❌ ScheduleEntity bulunamadı, ID: \(id)")
                throw RepositoryError.entityNotFound
            }
            
            scheduleEntityToUpdate.isActive = isActive
            scheduleEntityToUpdate.updatedAt = Date()
            logger.debug("✅ ScheduleEntity aktiflik durumu güncellendi: \(scheduleEntityToUpdate.name), isActive: \(isActive)")

            // 3. İlgili UserSchedule'ı güncelle
            try await updateUserScheduleState(scheduleId: uuid, isActive: isActive)
            
            try save()
            
            // Watch sync notification gönder
            if isActive {
                logger.debug("📡 Schedule aktivasyonu sonrası Watch sync tetikleniyor")
                NotificationCenter.default.post(
                    name: Notification.Name("ScheduleDidChange"),
                    object: nil,
                    userInfo: ["scheduleId": scheduleEntityToUpdate.id.uuidString]
                )
            }
            
        } catch {
            logger.error("❌ Program aktiflik durumu güncellenirken hata: \(error.localizedDescription)")
            throw RepositoryError.updateFailed
        }
    }
    
    /// Bir UserSchedule'ın adaptasyon fazını ve güncellenme tarihini günceller
    func updateUserScheduleAdaptationPhase(scheduleId: UUID, newPhase: Int) throws {
        logger.debug("🗂️ UserSchedule (ID: \(scheduleId.uuidString)) adaptasyon fazı güncelleniyor: \(newPhase)")
        
        let descriptor = FetchDescriptor<UserSchedule>(
            predicate: #Predicate<UserSchedule> { $0.id == scheduleId }
        )
        
        do {
            guard let scheduleToUpdate = try fetch(descriptor).first else {
                logger.error("❌ Adaptasyon fazı güncellenecek UserSchedule (ID: \(scheduleId.uuidString)) bulunamadı.")
                throw RepositoryError.entityNotFound
            }
            
            scheduleToUpdate.adaptationPhase = newPhase
            scheduleToUpdate.updatedAt = Date()
            
            try save()
            logger.debug("✅ UserSchedule (ID: \(scheduleId.uuidString)) adaptasyon fazı başarıyla güncellendi.")
        } catch {
            logger.error("❌ UserSchedule adaptasyon fazı güncellenirken hata: \(error.localizedDescription)")
            throw RepositoryError.updateFailed
        }
    }
    
    // MARK: - Private Helper Methods
    
    /// Belirtilen ID hariç diğer aktif programları pasifleştir
    private func deactivateOtherSchedules(exceptId: UUID) async throws {
        // Diğer ScheduleEntity'leri pasifleştir
        let activeScheduleEntitiesDescriptor = FetchDescriptor<ScheduleEntity>(
            predicate: #Predicate<ScheduleEntity> { $0.id != exceptId && $0.isActive == true && $0.isDeleted == false }
        )
        
        // Diğer UserSchedule'ları pasifleştir
        let activeUserSchedulesDescriptor = FetchDescriptor<UserSchedule>(
            predicate: #Predicate<UserSchedule> { $0.id != exceptId && $0.isActive == true }
        )

        do {
            let otherActiveSchedules = try fetch(activeScheduleEntitiesDescriptor)
            for schedule in otherActiveSchedules {
                schedule.isActive = false
                schedule.updatedAt = Date()
                logger.debug("🗂️ Önceki aktif ScheduleEntity pasifleştirildi: \(schedule.name)")
            }

            let otherActiveUserSchedules = try fetch(activeUserSchedulesDescriptor)
            for userSchedule in otherActiveUserSchedules {
                userSchedule.isActive = false
                userSchedule.updatedAt = Date()
                logger.debug("🗂️ Önceki aktif UserSchedule pasifleştirildi: \(userSchedule.name)")
            }
        } catch {
            logger.error("❌ Diğer aktif programlar pasifleştirilirken hata: \(error.localizedDescription)")
            // Devam et, ancak hatayı logla
        }
    }
    
    /// UserSchedule state'ini güncelle
    private func updateUserScheduleState(scheduleId: UUID, isActive: Bool) async throws {
        let userScheduleDescriptor = FetchDescriptor<UserSchedule>(
            predicate: #Predicate<UserSchedule> { $0.id == scheduleId }
        )
        
        if let userScheduleToUpdate = try fetch(userScheduleDescriptor).first {
            userScheduleToUpdate.isActive = isActive
            userScheduleToUpdate.updatedAt = Date()
            
            // Schedule değişikliğinde adaptasyon ilerlemesi korunur.
            // Sadece adaptationStartDate yoksa yeni başlangıç ata.
            if isActive {
                if userScheduleToUpdate.adaptationStartDate == nil {
                    userScheduleToUpdate.adaptationPhase = 0
                    userScheduleToUpdate.adaptationStartDate = Date()
                }
                logger.debug("🗂️ UserSchedule (ID: \(userScheduleToUpdate.id.uuidString)) aktif edildi, adaptasyon ilerlemesi korundu.")
            }
            logger.debug("✅ UserSchedule aktiflik durumu güncellendi: \(userScheduleToUpdate.name), isActive: \(isActive)")
        } else if isActive {
            // Bu durum bir tutarsızlığa işaret eder: ScheduleEntity var ama UserSchedule yok.
            logger.error("❌ TUTARSIZLIK: ScheduleEntity (ID: \(scheduleId.uuidString)) için UserSchedule bulunamadı ancak aktif edilmeye çalışılıyor.")
        }
    }
} 