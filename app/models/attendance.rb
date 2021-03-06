class Attendance < ApplicationRecord
  belongs_to :user
  has_one :correction, dependent: :destroy
  has_one :history, dependent: :destroy
  
  #余裕があればバリデーションをもっと見やすく！
  validates :worked_on, presence: true
  validates :note, length: { maximum: 50 }
  #残業申請、承認
  #勤怠変更申請、承認
  validates :applied_attendances_change, presence: true, on: :update_one_month
  
  #管理者は勤怠情報を入力できない
  validate :administrator_cannot_enter_attendance

  #出勤時間が存在しない場合、退勤時間は無効
  validate :finished_at_is_invalid_without_a_started_at
  #出勤・退勤時間がどちらも存在する時、出勤時間より早い退勤時間は無効
  validate :started_at_then_finished_at_fast_if_invalid
  #当日の勤怠データが存在する時、出勤時間のみの更新は無効
  validate :started_at_is_invalid_exist_a_finished_at
  #退勤時間が存在する時、終了予定時間の更新は無効
  # validate :finish_overwork_is_invalid_exist_a_finished_at
  #指定勤務終了時間より早い残業終了予定時間は無効
  #validate :finish_overwork_earlier_than_desig_finish_worktime_is_invalid
  #残業終了予定時間が存在する時、業務処理内容と残業申請送信先も同じく存在する
  validate :finish_overwork_exist_work_contents_applied_overwork_exist
  #申請時、所属長の選択が必要
  validate :attendance_change_application_necessary_superior_select
  
  def administrator_cannot_enter_attendance
    errors.add(:admin, "は勤怠情報を入力できません") if user.admin
  end
  
  def finished_at_is_invalid_without_a_started_at
    errors.add(:started_at, "が必要です") if started_at.blank? && finished_at.present?
  end
  
  def started_at_then_finished_at_fast_if_invalid
    if started_at.present? && finished_at.present?
      errors.add(:started_at, "より早い時間は無効です") if started_at > finished_at
    end
  end
  
  #出勤日当日でない日は、出勤時間のみの更新は無効
  def started_at_is_invalid_exist_a_finished_at
    if applied_attendances_change.present?
      unless worked_on == Date.current
        errors.add(:finished_at, "が必要です") if started_at.present? && finished_at.blank?
      end
    end
  end
  
  # def finish_overwork_is_invalid_exist_a_finished_at
  #   errors.add("退勤しているので、残業申請は無効です") if finished_at.present? && finish_overwork.present?
  # end
  
  #指定勤務終了時間より早い残業終了予定時間は無効
  # def finish_overwork_earlier_than_desig_finish_worktime_is_invalid
  #   if applied_overwork.present?
  #     if finish_overwork.present?
  #       if user.designated_work_end_time >= finish_overwork
  #         errors.add(:designated_work_end_time, "より早い時間は無効です")
  #       end
  #     end
  #   end
  # end
  
  #残業申請時、上長の選択と作業内容、残業終了予定時間の入力が必要
  def finish_overwork_exist_work_contents_applied_overwork_exist
    if overwork_confirmation == 2 && applied_overwork.nil?
        errors.add(:work_contents, "が必要です")
        errors.add(:applied_overwork, "が必要です")
        errors.add(:applied_overwork, "を選択してください")
    end
  end

  #勤怠変更申請時、上長の選択が必要
  def attendance_change_application_necessary_superior_select
    errors.add(:applied_attendances_change, "を選択してください") if change_attendances_confirmation == 2 && applied_attendances_change.nil?
  end

  #残業申請時翌日チェック有りの場合は+1日
  def one_day_plus_overwork
    self.finish_overwork += 1.day
  end  

  #勤怠変更申請時翌日チェック有りの場合は+1日
  def one_day_plus_month
    self.finished_at += 1.day
  end
end
