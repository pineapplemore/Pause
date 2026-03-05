# PuffDiary（屁屁记录）

为肠易激综合征（IBS）用户设计的放屁记录 iOS App，界面简约时尚。

## 功能

- **记录**：点击「记录一次」保存当前时间，可选类型多选（臭屁、闷屁、突突突屁、响屁、热屁、寒屁）
- **日历**：月历展示每日次数，点击日期查看当日记录列表，可左滑删除
- **统计**：周期选择（周 / 月 / 3个月 / 6个月 / 9个月 / 1年）、本周期总次数与日均、每日时段分布折线图、周期对比柱状图

## 运行

1. 用 Xcode 打开 `Puff/Puff.xcodeproj`
2. 选择模拟器或真机，运行 Scheme「Puff」

## 环境

- Xcode 13+
- iOS 15.0+
- Swift 5

## 项目结构

```
Puff/
  Puff.xcodeproj
  Puff/
    PuffApp.swift
    ContentView.swift
    Models/       (PuffType, PuffRecord)
    Services/    (StorageService)
    ViewModels/  (AppState)
    Views/        (RecordView, CalendarView, DayDetailView, StatisticsView)
    Assets.xcassets
    Info.plist
```

数据保存在本地 UserDefaults，无需网络。
