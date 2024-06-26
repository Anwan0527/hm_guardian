// TODO: 处理临界状态，安全渐变，警告渐变色
import { router } from '@kit.ArkUI'
import { statfs } from '@kit.CoreFileKit'
import { photoAccessHelper } from '@kit.MediaLibraryKit'
import { NavigationTitleBuilder } from '../../common/builders'
import { formatByteLength, GIGA_BYTE } from '../../common/utils'
import { themeManager } from '../../manager'
import { cleanerManager } from '../../manager/CleanerManger'

interface ClearItem {
  icon: ResourceStr
  name: string
  list: photoAccessHelper.PhotoAsset[]
  size: number
}

export interface PhotoInfo {
  uri: string
  display_name: string
  title: string
  media_type: number
  size: number
  date_added: number
  date_modified: number
  duration: number
  width: number
  height: number
  date_taken: number
  orientation: number
  is_favorite: number
}

@Entry
@Component
struct CleanerScanResultPage {
  // 总大小
  @State totalSize: number = 0
  // 可用大小
  @State freeSize: number = 0
  // 列表
  @State list: ClearItem[] = [
    {
      icon: $r('app.media.ic_clean_pmjt'),
      name: '屏幕截图',
      list: [],
      size: 0
    }, // 0
    {
      icon: $r('app.media.ic_clean_pmlz'),
      name: '视频文件',
      list: [],
      size: 0
    }, // 1
    {
      icon: $r('app.media.ic_clean_lpzp'),
      name: '连拍照片',
      list: [],
      size: 0
    }, // 2
    {
      icon: $r('app.media.ic_clean_zpzp'),
      name: '自拍照片',
      list: [],
      size: 0
    }, // 3
    {
      icon: $r("app.media.ic_clean_ljzp"),
      name: '滤镜照片',
      list: [],
      size: 0
    }, // 4
    {
      icon: $r('app.media.ic_clean_dttp'),
      name: '动态图片',
      list: [],
      size: 0
    },// 5
  ]

  onPageShow() {
    themeManager.settingStatusBarWhite()
    this.getStatfsSize()
    this.getData()
  }

  aboutToAppear() {
    cleanerManager.requestPermissions()
    this.getData()
  }

  async getData() {
    const screenshotList = await cleanerManager.getScreenshotList()
    const videoList = await cleanerManager.getVideoList()
    let screenshotSize = 0
    screenshotList.forEach(item => {
      const size = item.get(photoAccessHelper.PhotoKeys.SIZE) as number
      screenshotSize += size
    })
    //更新截图列表信息
    this.list[0] = {
      icon: $r('app.media.ic_clean_pmjt'),
      name: '屏幕截图',
      list: screenshotList,
      size: screenshotSize
    }
    //更新视频列表信息
    this.list[1] = {
      icon: $r('app.media.ic_clean_pmlz'),
      name: '视频文件',
      list: videoList,
      size: 0
    }
  }

  onPageHide() {
    themeManager.settingStatusBarBlack()
  }

  // 获取剩余存储
  async getStatfsSize() {
    const context = getContext()
    // 字节数转GB
    this.freeSize = statfs.getFreeSizeSync(context.filesDir)
    this.totalSize = statfs.getTotalSizeSync(context.filesDir)
  }

  build() {
    Navigation() {
      // 顶部区域
      Stack({ alignContent: Alignment.Bottom }) {
        Column() {
          Row({ space: 5 }) {
            Text((this.freeSize / GIGA_BYTE).toFixed(1))
              .fontSize(50)
              .fontColor($r('app.color.white'))
            Column() {
              Text('剩余\nGB')
                .fontSize(16)
                .fontColor($r('app.color.white'))
                .lineHeight(22)
            }
          }

          Text(`已用空间：${Math.round((1 - this.freeSize / this.totalSize) * 100)}%`)
            .fontSize(14)
            .fontColor($r('app.color.white'))
        }
        .height('100%')
        .justifyContent(FlexAlign.Start)
        .padding({ top: 50 })

        Row() {
          Text('照片太多了，赶快处理下吧')
            .fontSize(14)
            .fontColor($r('app.color.white'))
            .width('100%')
            .textAlign(TextAlign.Center)
          Ellipse()
            .width(500)
            .height(80)
            .fill('#26ffffff')
            .position({ x: '50%' })
            .translate({ x: '-50%', y: 0 })
        }
        .width('100%')
        .height(42)
      }
      .height(210)

      Column() {
        // 列表
        List() {
          ForEach(this.list, (item: ClearItem) => {
            if (item.list.length > 0) {
              ListItem() {
                // 列表项 - 有图
                Column({ space: 10 }) {
                  Row({ space: 10 }) {
                    Image(item.icon)
                      .width(34)
                      .aspectRatio(1)
                      .backgroundColor($r('app.color.background'))
                      .borderRadius(6)
                    Column({ space: 4 }) {
                      Text() {
                        Span(item.list.length.toString())
                        Span(' ')
                        Span(item.name)
                          .fontColor($r('app.color.font2'))
                      }
                      .fontSize(16)
                      .fontColor($r('app.color.brand'))

                      Text() {
                        Span('清理后可节省')
                        Span(formatByteLength(item.size))
                      }
                      .fontSize(12)
                      .fontColor($r('app.color.font_sub'))
                    }
                    .alignItems(HorizontalAlign.Start)
                    .layoutWeight(1)

                    Button('立即查看')
                      .type(ButtonType.Normal)
                      .backgroundColor($r('app.color.brand'))
                      .borderRadius(10)
                      .height(24)
                      .fontSize(12)
                  }
                  .width('100%')

                  GridRow({ gutter: 8, columns: 4 }) {
                    ForEach(item.list.slice(0, 4), (item: photoAccessHelper.PhotoAsset) => {
                      GridCol() {
                        if (item.photoType === photoAccessHelper.PhotoType.IMAGE) {
                          // 图片
                          Image(item.uri)
                            .width('100%')
                            .aspectRatio(1)
                            .borderRadius(6)
                        } else if (item.photoType === photoAccessHelper.PhotoType.VIDEO) {
                          // 视频
                          Video({ src: item.uri })
                            .width('100%')
                            .aspectRatio(1)
                            .borderRadius(6)
                            .autoPlay(true)
                            .muted(true)
                            .controls(false)
                        }
                      }
                    })
                  }
                }
                .padding(15)
                .onClick(() => {
                  router.pushUrl({
                    url: 'pages/Cleaner/CleanerSelectPage',
                    params: { name: item.name }
                  })
                })
              }
            }
          })

          ListItem() {
            // 列表项 - 无图
            Column({ space: 10 }) {
              Row({ space: 10 }) {
                Column({ space: 4 }) {
                  Text() {
                    Span('照片瘦身(压缩）')
                      .fontColor($r('app.color.font2'))
                  }
                  .fontSize(16)
                  .fontColor($r('app.color.brand'))

                  Text('清晰度几乎一样，请放心使用')
                    .fontSize(12)
                    .fontColor($r('app.color.font_sub'))
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)

                Button('立即查看')
                  .type(ButtonType.Normal)
                  .backgroundColor($r('app.color.brand'))
                  .borderRadius(10)
                  .height(24)
                  .fontSize(12)
              }
              .width('100%')
              .onClick(() => {
                router.pushUrl({ url: 'pages/Cleaner/Compress/CompressPhotoPage' })
              })

            }
            .padding(20)
          }
        }
        .divider({ strokeWidth: 10, color: $r('app.color.background') })
        .width('100%')
        .height('100%')
      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor($r('app.color.white'))
    }
    .title(NavigationTitleBuilder('手机瘦身'))
    .hideBackButton(true)
    .titleMode(NavigationTitleMode.Mini)
    .mode(NavigationMode.Stack)
    .linearGradient({
      direction: 180,
      colors: [['#F36F65', 0], ['#F4B265', 0.4], [$r('app.color.white'), 0.4]]
    })
  }
}