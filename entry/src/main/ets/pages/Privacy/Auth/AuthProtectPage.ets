// DONE: 未输入内容时，点击下一步，输入框的 placeholder 文案抖动
import { PRIVACY_QUESTION_LIST, PRIVACY_SETTINGS, PrivacySettings } from '../../../common/constants';
import { promptAction, router } from '@kit.ArkUI';
import { encryptMD5 } from '../../../common/utils/encryptMD5';

interface RouterParams {
  patternPassword?: number[]
}


@Entry
@Component
struct AuthProtect {
  // 双向绑定 Storage 数据
  @StorageLink(PRIVACY_SETTINGS) privacySettings: PrivacySettings = {}
  // 问题下标
  @State activeIndex: number = 0
  // 问题答案
  @State answerText: string = ''
  // 错误提示语
  @State errorMessage: string = ''
  // 空状态，输入框抖动效果
  @State inputPaddingLeft: number = 10
  // 路由参数
  @State routerParams: RouterParams = {}

  aboutToAppear() {
    if (router.getParams() as RouterParams)
      this.routerParams = router.getParams() as RouterParams
  }

  async onSubmit() {
    if (this.answerText == '') {
      this.errorMessage = '密保问题不能为空'
      this.inputPaddingLeft = 14
    } else {
      const res = await promptAction.showDialog({
        title: '温馨提示',
        message: `你设定的密码保护问题如下\n问题：${PRIVACY_QUESTION_LIST[this.activeIndex].value}\n答案：${this.answerText}\n请确保能够牢记！`,
        buttons: [
          { text: '取消', color: $r('app.color.font_sub') },
          { text: '确定', color: $r('app.color.brand') },
        ]
      })
      if (res.index = 1) {
        this.privacySettings.patternPassword = encryptMD5(this.routerParams.patternPassword!.toString()) //图案密码
        this.privacySettings.protectQuestionIndex = this.activeIndex //密保问题
        this.privacySettings.protectQuestionAnswer = encryptMD5(this.answerText) //密保答案
        router.pushUrl({ url: 'pages/Privacy/PrivacyIndexPage' })
      }
    }
  }

  @Builder
  NavigationMenus() {
    Row() {
      Text('完成')
        .fontSize(16)
        .fontColor($r('app.color.font'))
        .onClick(() => {
          // TODO：完成
          this.onSubmit()
        })
    }
    .height('100%')
    .padding({ right: 25 })
  }

  build() {
    Navigation() {
      Column() {
        Text('设置密码保护问题')
          .fontSize(16)
          .fontColor($r('app.color.font'))
        Text(this.errorMessage ? this.errorMessage : '忘记密码时，可通过密码保护问题重置')
          .fontSize(12)
          .fontColor(this.errorMessage ? $r('app.color.danger') : $r('app.color.font_sub'))
          .lineHeight(25)
        Column() {
          Select(PRIVACY_QUESTION_LIST)
            .value(PRIVACY_QUESTION_LIST[this.activeIndex].value)
            .selected(this.activeIndex)
            .font({ size: 16, weight: 500 })
            .fontColor($r('app.color.font'))
            .selectedOptionFont({ size: 16, weight: 500 })
            .optionFont({ size: 16, weight: 400 })
            .optionBgColor(Color.Transparent)
            .selectedOptionBgColor(Color.Transparent)
            .width('100%')
            .height(56)
            .padding(0)
            .border({ width: { bottom: 1 }, color: $r('app.color.border'), radius: 0 })// 需去除圆角
            .onSelect((index) => {
              this.activeIndex = index
            })

          Row() {
            TextInput({ placeholder: '密保问题答案', text: $$this.answerText })
              .cancelButton({
                style: CancelButtonStyle.INPUT, // 输入时显示清空按钮
                icon: { src: $r('app.media.ic_public_cancel_button') }  // 设置右侧清除按钮样式
              })
              .defaultFocus(true)// 自动获取焦点
              .backgroundColor(Color.Transparent)
              .width('100%')
              .height(56)
              .padding(0)
              .onSubmit(() => {
                // TODO：提交密保问题答案
                this.onSubmit()
              })
          }
          .border({ width: { bottom: 1 }, color: $r('app.color.border'), radius: 0 })
          .padding({ left: this.inputPaddingLeft })
          .animation({
            duration: 400,
            tempo: 4,
            iterations: 2,
            curve: Curve.Linear,
            onFinish: () => {
              // 动画结束，恢复默认值
              this.inputPaddingLeft = 10
            }
          })
        }
        .width('100%')
        .padding({ left: 20, right: 20 })
        .margin({ top: 20 })
      }
      .padding({ top: 140 })
    }
    .title('设置密保')
    .titleMode(NavigationTitleMode.Mini)
    .mode(NavigationMode.Stack)
    .menus(this.NavigationMenus)
    .renderFit(RenderFit.LEFT)
  }
}
