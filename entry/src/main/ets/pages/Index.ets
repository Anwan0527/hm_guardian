import { LoginInfoResponse, LOGIN_INFO, PrivacySettings, PRIVACY_SETTINGS } from '../common/constants';
import { themeManager } from '../manager';
import { GuardTabsComp } from './Tabs/GuardTabsComp';
import { HomeTabsComp } from './Tabs/HomeTabsComp';
import { MyTabsComp } from './Tabs/MyTabsComp';

// TODO: 切换页面时，更新我的页面信息
PersistentStorage.persistProp<PrivacySettings>(PRIVACY_SETTINGS, {}) //数据持久化
PersistentStorage.persistProp<LoginInfoResponse>(LOGIN_INFO, {})

@Entry
@Component
struct Index {
  @State currentIndex: number = 0
  @StorageLink('bottomHeight') bottomHeight: number = 0

  onPageShow() {
    themeManager.enableFullScreen()
  }

  onPageHide() {
    themeManager.disableFullScreen()
  }

  @Builder
  TabBuilder(title: string, targetIndex: number, selectedImg: Resource, normalImg: Resource) {
    Column() {
      Image(this.currentIndex === targetIndex ? selectedImg : normalImg)
        .width(20)
        .aspectRatio(1)
      Text(title)
        .fontSize(10)
        .fontColor(this.currentIndex === targetIndex ? $r('app.color.brand') : $r('app.color.font'))
        .margin({ top: 4 })
    }
    .width('100%')
    .height(56)
    .border({ width: { top: 1 }, color: '#eee' })
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      this.currentIndex = targetIndex;
    })
  }

  build() {
    Tabs({ index: this.currentIndex, barPosition: BarPosition.End }) {
      TabContent() {
        HomeTabsComp()
      }
      .tabBar(this.TabBuilder('首页', 0, $r('app.media.ic_tab_shouye_filled'), $r('app.media.ic_tab_shouye')))

      TabContent() {
        GuardTabsComp()
      }
      .tabBar(this.TabBuilder('守护中心', 1, $r('app.media.ic_tab_shzx_filled'), $r('app.media.ic_tab_shzx')))

      TabContent() {
        MyTabsComp({ currentIndex: this.currentIndex })
      }
      .tabBar(this.TabBuilder('我的', 2, $r('app.media.ic_tab_wode_filled'), $r('app.media.ic_tab_wode')))
    }
    .barMode(BarMode.Fixed) // 默认值 Fixed
    .scrollable(false) // 限制滑动
    .padding({ bottom: this.bottomHeight })
  }
}