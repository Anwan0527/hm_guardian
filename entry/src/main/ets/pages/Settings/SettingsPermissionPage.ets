import { Permissions } from '@kit.AbilityKit';
import { NavigationTitleBuilder } from '../../common/builders';
import { permissionManager, themeManager } from '../../manager';
import { promptAction } from '@kit.ArkUI';
import { notificationManager } from '@kit.NotificationKit';

interface PermissionItem {
  name: string
  title: string
  desc: string
  permissions: Permissions[]
  timeStamp: number // 用于更新授权状态
}

@Entry
@Component
struct SettingsPermissionPage {
  @State isNotificationEnabled: boolean = false
  @State permissionList: PermissionItem[] = [
    {
      name: 'notification',
      title: '通知',
      desc: '开启后可以获得安全播报，号码包升级等',
      permissions: [],
      timeStamp: 0
    },
    // 对所有应用开放的权限
    {
      name: 'camera',
      title: '相机',
      desc: '开启后才能使用安全扫码等功能',
      permissions: ['ohos.permission.CAMERA'],
      timeStamp: 0
    },
    {
      name: 'microphone',
      title: '麦克风',
      desc: '开启后才能录制加密视频和音频',
      permissions: ['ohos.permission.MICROPHONE'],
      timeStamp: 0
    },
    {
      name: 'calendar',
      title: '日历',
      desc: '开启后才能帮您清理诈骗日历、过期日历',
      permissions: ['ohos.permission.READ_CALENDAR', 'ohos.permission.WRITE_CALENDAR'],
      timeStamp: 0
    },
    {
      name: 'location',
      title: '位置',
      desc: '开启后精准显示空气指数，识别骚扰号码更加精准',
      permissions: ['ohos.permission.APPROXIMATELY_LOCATION', 'ohos.permission.LOCATION'],
      timeStamp: 0
    },
    // 允许ACL跨级别申请的权限
    {
      name: 'image_video',
      title: '照片',
      desc: '开启后才能帮您通过照片瘦身节省空间',
      permissions: ['ohos.permission.READ_IMAGEVIDEO', 'ohos.permission.WRITE_IMAGEVIDEO'],
      timeStamp: 0
    },
    {
      name: 'contacts',
      title: '通讯录',
      desc: '开启后才能帮您进行通讯录的备份、恢复和优化',
      permissions: ['ohos.permission.READ_CONTACTS', 'ohos.permission.WRITE_CONTACTS'],
      timeStamp: 0
    },
  ]

  onPageShow() {
    themeManager.settingStatusBarWhite()
  }

  onPageHide() {
    themeManager.settingStatusBarBlack()
  }

  //更新视图
  async updatePermissionState() {
    this.permissionList = this.permissionList.map<PermissionItem>((item) => {
      return {
        name: item.name,
        title: item.title,
        desc: item.desc,
        permissions: item.permissions,
        timeStamp: Date.now()
      }
    })
    // 更新通知权限状态
    this.isNotificationEnabled = await notificationManager.isNotificationEnabled()
  }

  //通知授权
  async requestNotification() {
    try {
      await notificationManager.requestEnableNotification()
      this.updatePermissionState()
    } catch (err) {
      permissionManager.openPermissionSettingsPage()
    }
  }

  //申请权限
  async requestPermission(permission: Permissions[]) {
    const isAuth = await permissionManager.requestPermissions(permission)
    this.updatePermissionState()
    if (isAuth == false) permissionManager.openPermissionSettingsPage()

  }

  // 关闭权限，应用内无法关闭权限，弹窗提示去设置页关闭
  async closePermission() {
    // 弹窗确认
    const res = await promptAction.showDialog({
      alignment: DialogAlignment.Center,
      title: '提示',
      message: '关闭以上权限将不能完整使用守护助手为您提供的服务，是否需要关闭？',
      buttons: [
        { text: '取消', color: $r('app.color.brand') },
        { text: '去设置关闭', color: $r('app.color.font_sub') },
      ]
    })
    // 点击确定
    if (res.index === 1) {
      permissionManager.openPermissionSettingsPage()
    }
  }

  build() {
    Navigation() {
      Row() {
        Text('建议您开启全部权限\n体验小卫更精准、更贴心的功能！')
          .fontSize(14)
          .fontColor($r('app.color.white'))
          .lineHeight(20)
          .textAlign(TextAlign.Center)
      }
      .height(180 - 56)

      Column() {
        ForEach(this.permissionList, (item: PermissionItem) => {
          Row() {
            Column({ space: 5 }) {
              Text(item.title)
                .fontSize(16)
                .fontWeight(500)
                .fontColor($r('app.color.font'))
              Text(item.desc)
                .fontSize(12)
                .fontColor($r('app.color.font_sub'))
            }
            .alignItems(HorizontalAlign.Start)


            if (item.name === 'notification') {
              if (this.isNotificationEnabled) {
                Text('已开启')
                  .fontSize(14)
                  .fontColor($r('app.color.brand'))
              } else {
                Toggle({ type: ToggleType.Switch, isOn: false })
                  .onChange(() => {
                    this.requestNotification()
                  })
              }
            } else {
              // 是否已开启权限
              if (permissionManager.checkPermissions(item.permissions)) {
                Text('已开启')
                  .fontSize(14)
                  .fontColor($r('app.color.brand'))
              } else {
                // ToggleType.Switch  控制外观
                // isOn: 初始值，true 为选中，false 未选中
                Toggle({ type: ToggleType.Switch, isOn: permissionManager.checkPermissions(item.permissions) })
                  .onChange(async () => {
                    // 更新所有权限授权状态
                    this.requestPermission(item.permissions)
                  })
              }
            }
          }
          .width('100%')
          .height(64)
          .justifyContent(FlexAlign.SpaceBetween)
        })
        Button('关闭权限')
          .fontColor($r('app.color.font_sub'))
          .backgroundColor(Color.Transparent)
          .margin({ top: 20 })
          .onClick(() => {
            this.closePermission()
          })
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ left: 20, right: 20 })
      .backgroundColor($r('app.color.white'))
    }
    .title(NavigationTitleBuilder('权限管理'))
    .titleMode(NavigationTitleMode.Mini)
    .mode(NavigationMode.Stack)
    .hideBackButton(true)
    .linearGradient({
      angle: 180,
      colors: [[$r('app.color.brand'), 0], [$r('app.color.brand_light'), 0.25], [$r('app.color.white'), 0.25]]
    })
  }
}