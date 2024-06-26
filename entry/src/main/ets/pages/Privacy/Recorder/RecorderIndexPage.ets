import { ValuesBucket } from '@kit.ArkData'
import dayjs from 'dayjs'
import duration from 'dayjs/plugin/duration'
import { EmptyTipsComp } from '../../../common/components'
import { CustomInputDialog } from '../../../common/dialog'
import { audioCapturerManager } from '../../../manager'
import { fileIo } from '@kit.CoreFileKit'
import { PRIVACY_RECORDER_FOLDER } from '../../../common/constants'
import { privacyRecorderDB } from '../../../common/database'
import { deviceInfo } from '@kit.BasicServicesKit'

export interface PrivacyRecorderDBInfo extends ValuesBucket {
  id: number | null // 新增时 id 为 null ，自动生成自增 id
  filePath: string
  title: string
  date_added: number
  duration: number
}

dayjs.extend(duration)

@Entry
@Component
struct RecorderIndexPage {
  @State list: PrivacyRecorderDBInfo[] = []
  @State tempInputText: string = ''
  @State onConfirmEnable: boolean = true
  @State activeItem: PrivacyRecorderDBInfo | null = null
  @State isRecording: boolean = false
  @State isPlaying: boolean = false
  @State recordingTime: number = 0
  @State playingTime: number = 0
  // 自定义弹窗层
  dialogController: CustomDialogController = new CustomDialogController({
    builder: CustomInputDialog({
      title: '重命名音频',
      message: '支持下划线、数宇、英文字母与中文',
      inputText: this.tempInputText,
      onConfirm: async () => {
        // TODO：重命名录音
        this.renameRecorder()
      },
    }),
    autoCancel: true,
    customStyle: true,
    alignment: DialogAlignment.Center,
  })
  private playingTimerId: number = -1
  private recordingTimerId: number = -1

  //重命名录音
  async renameRecorder() {
    if (this.activeItem) {
      await privacyRecorderDB.update({
        title: this.tempInputText,
        id: this.activeItem.id,
        date_added: this.activeItem.date_added,
        duration: this.activeItem.duration,
        filePath: this.activeItem.filePath
      })
      this.getList()
    }
  }

  //删除录音
  async deleteRecorder(item: PrivacyRecorderDBInfo) {
    if (deviceInfo.marketName !== 'emulator') {
      audioCapturerManager.stopRenderer()
    }
    //删除数据库
    if (item.id) {
      await privacyRecorderDB.delete(item.id)
    }
    //获取列表
    this.getList()
    //删除文件
    fileIo.unlink(item.filePath)
  }

  //开始播放
  playRecorder(item: PrivacyRecorderDBInfo) {
    this.activeItem = item
    if (this.isPlaying == false) {
      //如果没播放——>更新播放状态
      this.isPlaying = true
      this.startPlayingCount()
      audioCapturerManager.startRenderer(item.filePath)
    } else {
      this.isPlaying = false
      this.stopPlayingCount()
      audioCapturerManager.stopRenderer()
    }
  }

  // 开启播放进度条
  startPlayingCount() {
    this.playingTime = 0
    // 时间间隔
    const interval = 20
    clearInterval(this.playingTimerId)
    this.playingTimerId = setInterval(() => {
      // 累加进度条
      this.playingTime += interval
      if (this.playingTime >= this.activeItem!.duration) {
        this.stopPlayingCount()
      }
    }, interval)
  }

  // 结束播放进度条
  stopPlayingCount() {
    this.isPlaying = false
    clearInterval(this.playingTimerId)
  }

  //开始录音
  startCapturer() {
    this.isRecording = true
    this.startCounter()
    const context = getContext()
    const filePath = context.filesDir + '/' + PRIVACY_RECORDER_FOLDER + '/' + Date.now() + '.wav'
    // AlertDialog.show({
    //   message: JSON.stringify(filePath)
    // })
    audioCapturerManager.startCapturer(filePath)
  }

  //结束录音
  async stopCapturer() {
    this.isRecording = false
    this.stopCounter()
    // 如果是模拟器 emulator ，直接模拟写入数据库，查询列表，用于测试进度条
    if (deviceInfo.marketName === 'emulator') {
      await privacyRecorderDB.insert({
        id: null,
        filePath: '/',
        title: '测试用的录音标题',
        date_added: Date.now(),
        duration: this.recordingTime * 1000
      })
      this.getList()
      return
    }
    const audioInfo = await audioCapturerManager.stopCapturer()
    //写入数据库
    await privacyRecorderDB.insert({
      id: null,
      filePath: audioInfo.filePath,
      title: '录音' + audioInfo.date_added,
      date_added: audioInfo.date_added,
      duration: audioInfo.duration
    })
    this.getList()
  }

  async getList() {
    this.list = await privacyRecorderDB.query()
  }

  //开始计时
  startCounter() {
    //初始化
    this.recordingTime = 0
    //清除以前计时器
    clearInterval(this.recordingTimerId)
    //开启定时器
    this.recordingTimerId = setInterval(() => {
      this.recordingTime++
    }, 1000)
  }

  //结束计时
  stopCounter() {
    clearTimeout(this.recordingTimerId)
  }

  aboutToAppear() {
    //获取录音权限
    audioCapturerManager.requestPermissions()
    this.initFolder() //初始化
    this.getList()
  }

  // 初始化隐私录音目录，如果文件夹不存在先创建文件夹
  initFolder() {
    //上下文
    const context = getContext()
    //目录
    const fileDir = context.filesDir
    //获取文件夹
    const list = fileIo.listFileSync(fileDir)
    if (list.includes(PRIVACY_RECORDER_FOLDER) == false) {
      fileIo.mkdirSync(fileDir + '/' + PRIVACY_RECORDER_FOLDER)
    }
  }

  @Builder
  NavigationMenus() {
    Row() {
      Text('编辑')
        .fontSize(16)
        .fontColor($r('app.color.font'))
        .onClick(() => {

        })
    }
    .height('100%')
    .padding({ right: 25 })
  }

  @Builder
  ListItemSwipeActionEnd(item: PrivacyRecorderDBInfo) {
    Row() {
      Button("重命名")
        .type(ButtonType.Normal)
        .height('100%')
        .aspectRatio(1)
        .backgroundColor('#CECFCF')
        .onClick(() => {
          // TODO：录音重命名
          this.dialogController.open()
          this.tempInputText = item.title //传参
          // 3. 保存当前点击的信息
          this.activeItem = item

        })
      Button("删除")
        .type(ButtonType.Normal)
        .height('100%')
        .aspectRatio(1)
        .backgroundColor('#FF5E5D')
        .onClick(() => {
          // TODO：删除录音
          this.deleteRecorder(item)
        })
    }
    .height('100%')
    .justifyContent(FlexAlign.SpaceEvenly)
  }

  build() {
    Navigation() {
      Stack({ alignContent: Alignment.Bottom }) {
        Column() {
          if (this.list.length) {
            List() {
              ListItemGroup() {
                ForEach(this.list, (item: PrivacyRecorderDBInfo) => {
                  ListItem() {
                    Row({ space: 20 }) {
                      Column({ space: 10 }) {
                        Text(item.title)
                          .fontSize(16)
                          .fontColor($r('app.color.font2'))
                        // 录音进度条
                        if (this.activeItem?.id === item.id && this.isPlaying) {
                          Row({ space: 5 }) {
                            Text(dayjs(this.playingTime)
                              .format('mm:ss'))
                              .fontSize(12)
                              .fontColor($r('app.color.font_sub'))
                            Progress({
                              //进度条
                              value: this.playingTime,
                              total: item.duration,
                            })
                          }
                          .padding({ right: 20 })
                        } else {
                          Text(dayjs(item.date_added)
                            .format('YYYY年MM月DD日 HH:mm:ss'))
                            .fontSize(12)
                            .fontColor($r('app.color.font_sub'))
                        }
                      }
                      .alignItems(HorizontalAlign.Start)
                      .layoutWeight(1)

                      Column() {
                        Image(
                          this.activeItem?.id === item.id && this.isPlaying ?
                          $r('sys.media.ohos_ic_public_pause') :
                          $r("app.media.ic_public_play")
                        )
                          .width(22)
                          .aspectRatio(1)
                          .fillColor('#A6B6C4')

                        Text(dayjs.duration(item.duration, 'milliseconds').format('mm:ss').toString())
                          .fontSize(12)
                          .fontColor('#A6B6C4')
                          .lineHeight(25)
                      }
                      .justifyContent(FlexAlign.Center)
                      .height('100%')
                      .onClick(() => {
                        // TODO：播放音频
                        this.playRecorder(item)
                      })
                    }
                    .width('100%')
                    .justifyContent(FlexAlign.SpaceBetween)
                    .padding({ left: 15, right: 15 })
                  }
                  .height(72)
                  .transition({ type: TransitionType.Delete, opacity: 0 })
                  .swipeAction({
                    end: {
                      builder: this.ListItemSwipeActionEnd(item),
                      onStateChange: (state) => {
                        if (state === SwipeActionState.EXPANDED) {
                          // 保存当前滑动的数据
                          this.activeItem = item
                        }
                      }
                    },
                    edgeEffect: SwipeEdgeEffect.None,
                  })
                })
              }
              .padding({ bottom: 126 })
              .divider({
                strokeWidth: 1,
                color: $r('app.color.border'),
                startMargin: 15,
                endMargin: 15
              })
            }
            // 每行之间的分界线
            .width('100%')
            .height('100%')
          } else {
            EmptyTipsComp({ title: '您还没有任何隐私录音\n点击下面的按钮开始创建' })
          }
        }
        .height('100%')

        // 录音按钮
        Column() {
          Image($r('app.media.ic_circle_recorder'))
            .width(56)
            .aspectRatio(1)
            .onClick(() => {
              // TODO：开始录音
              this.startCapturer()
            })
        }
        .width('100%')
        .height(126)
        .justifyContent(FlexAlign.Center)
        .padding({ left: 15, right: 15 })

        // 停止录音
        Column({ space: 15 }) {
          Row({ space: 12 }) {
            Row() {
              ForEach(Array.from({ length: 12 }), () => {
                Column()
                  .width(5)
                  .height(16)
                  .backgroundColor('#80ffffff')
                  .borderRadius(5 / 2)
              })
            }
            .width(110)
            .justifyContent(FlexAlign.SpaceBetween)

            // 图标
            Image($r('app.media.ic_recorder_fill'))
              .height('100%')

            Row() {
              ForEach(Array.from({ length: 12 }), () => {
                Column()
                  .width(5)
                  .height(16)
                  .backgroundColor('#80ffffff')
                  .borderRadius(5 / 2)
              })
            }
            .width(110)
            .justifyContent(FlexAlign.SpaceBetween)
          }
          .justifyContent(FlexAlign.Center)
          .width('100%')
          .height(58)
          .margin({ top: 40 })

          Text(
            dayjs.duration(this.recordingTime, 'seconds')
              .format(this.recordingTime > 1000 * 60 * 60 ? 'HH:mm:ss' : 'mm:ss')
          )
            .fontSize(18)
            .lineHeight(25)
            .fontWeight(700)
            .fontColor($r('app.color.white'))

          Row() {
            Button('停止录音')
              .type(ButtonType.Normal)
              .width('100%')
              .backgroundColor($r('app.color.brand'))
              .border({ width: 1, color: $r('app.color.white') })
              .borderRadius(10)
              .onClick(() => {
                // TODO：停止录音
                this.stopCapturer()
              })
          }
          .padding({ left: 15, right: 15 })
        }
        .width('101%')
        .height(222)
        .backgroundImage('/common/images/RecorderAddPage_bg_bottom.png')
        .backgroundImageSize(ImageSize.Cover)
        .visibility(this.isRecording ? Visibility.Visible : Visibility.None)
      }
      .height('100%')
    }
    .title('录音')
    .titleMode(NavigationTitleMode.Mini)
    .mode(NavigationMode.Stack)
    .menus(this.NavigationMenus)
    .linearGradient({
      angle: 180,
      colors: this.isRecording ? [[$r('app.color.white'), 0.95], [$r('app.color.brand'), 0.95]] :
        [[$r('app.color.white'), 0], [$r('app.color.white'), 1]]
    })
  }
}