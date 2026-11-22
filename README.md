# 屿灯 iOS

安卓那套（`D:\tools\walkie`）的 iPhone 版。同一套线协议，不用改安卓。
界面是 UIKit 写的，**iOS 12 及以上都能装**（SwiftUI 要 13，所以没用它）。

## 里面的东西

| 文件 | 干什么 |
|---|---|
| `Yudeng/Protocol.swift` | 643 字节音频包、名字包、音乐包、音量。跟安卓一个字节都不差 |
| `Yudeng/Socket.swift` | UDP 口子、广播、找本机地址 |
| `Yudeng/Server.swift` | 当主机时的转发、找主机 |
| `Yudeng/Audio.swift` | 录音 → 16k 单声道 20ms 一包；单节点排队播放；回声消除 |
| `Yudeng/WalkieEngine.swift` | 谁在说、几个人、名字、槽位、丢包加厚缓冲 |
| `Yudeng/Ride.swift` | 一趟、路线、距离/均速/最高、断裂检测 |
| `Yudeng/RideTracker.swift` | CoreLocation 记录、后台定位 |
| `Yudeng/*View.swift` | 主界面 / 骑行 / 记录 / 引导 / 折线 |

## 跟安卓不一样的两处（做不了，不是没做）

1. **放歌**：安卓用 MediaProjection 抓系统声音，iOS 没有公开接口，App 抓不到别的软件的声音。
2. **蓝牙耳机电量**：iOS 不给 App 读，只显示当前用的是哪个耳机。

其余对齐：对讲、谁在说话的点、在线人数、名单、昵称、主机/客户端、骑行记录、路线、偏了震、导出。

## 编

```
brew install xcodegen
xcodegen generate
xcodebuild -project Yudeng.xcodeproj -scheme Yudeng -sdk iphoneos \
  -configuration Release -derivedDataPath build \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO build
```

没有 Mac 就用 GitHub Actions，见 `.github/workflows/ios.yml`；
装到手机上怎么签，见 `怎么装.md`。
