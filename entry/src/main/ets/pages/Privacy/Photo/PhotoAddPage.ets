import { NavigationTitleBuilder } from '../../../common/builders'
import { AlbumInfo, PhotoInfo, photoManager } from '../../../manager'
import { fileIo, fileUri } from '@kit.CoreFileKit'
import { PRIVACY_PHOTO_FOLDER } from '../../../common/constants'
import { privacyPhotoDB, PrivacyPhotoDBInfo } from '../../../common/database'
import { router } from '@kit.ArkUI'
import { camera, cameraPicker } from '@kit.CameraKit'
import { photoAccessHelper } from '@kit.MediaLibraryKit'


interface tabItem {
  id: number
  title: string
}

@Entry
@Component
struct PhotoAddPage {
  @State @Watch('currentIndexChange') currentIndex: number = 0
  @State selectUris: string[] = []
  @State tabList: tabItem[] = [{ id: 0, title: '默认相册' }, { id: 1, title: '其他相册' },]
  @State photos: PhotoInfo[] = [] // 图片数组
  @State albums: AlbumInfo[] = [] // 相册数组
  @State albumPhotos: PhotoInfo[] = [] // 相册图片数组
  @State isEncrypting: boolean = false
  @State isShowUserAlbumPhoto: boolean = false
  @State completeCount: number = 0

  onBackPress(): boolean | void {
    if (this.isShowUserAlbumPhoto && this.currentIndex == 1) {
      this.isShowUserAlbumPhoto = false
      return true
    }
  }

  onPageShow() {
    this.getPhotoes()
    this.getAlbums()
  }

  currentIndexChange() {
    this.selectUris = []
  }

  async getAlbums() {
    this.albums = await photoManager.getAlbums()
  }

  async getPhotoes() {
    this.photos = await photoManager.getPhotoes()
  }

  async takePhoto() {
    //相机拍照
    const context = getContext()
    //准备隐私相册路径
    const filePath = context.filesDir + '/' + PRIVACY_PHOTO_FOLDER + '/' + Date.now() + '.jpg'
    //参数要求文件可写
    fileIo.openSync(filePath, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE)
    //把path 转成uri
    const saveUri = fileUri.getUriFromPath(filePath)

    //相机选择器
    const pickerResult = await cameraPicker.pick(
      getContext(),
      [cameraPicker.PickerMediaType.PHOTO],
      {
        cameraPosition: camera.CameraPosition.CAMERA_POSITION_BACK, //后置摄像头
        saveUri: saveUri//保存路径，不设置默认系统相册
      }
    )
    if (pickerResult.resultUri) {
      //写入数据库
      await privacyPhotoDB.insert({
        id: null,
        mediaUri: '', //隐私相册拍照 没有Uri
        privacyUri: pickerResult.resultUri,
        media_type: photoAccessHelper.PhotoType.IMAGE,
        date_added: Date.now()
      })
    }
  }

  //添加图片下一步
  async copyPhotosToPrivacy() {
    this.completeCount = 0
    this.isEncrypting = true
    const promiseTasks = this.selectUris.map(async uri => {
      //打开文件
      const originFile = fileIo.openSync(uri)
      const context = getContext()
      const filePath = context.filesDir + '/' + PRIVACY_PHOTO_FOLDER + '/' + Date.now() + '.jpg'
      //复制文件
      fileIo.copyFileSync(originFile.fd, filePath)
      //根据uri查找完整信息
      const item = this.photos.find(v => v.uri == uri)
      if (item) {
        //数据库要求格式
        const data: PrivacyPhotoDBInfo = {
          id: null,
          mediaUri: uri,
          privacyUri: fileUri.getUriFromPath(filePath),
          media_type: item.media_type,
          date_added: item.date_added
        }
        //返回promise数据
        this.completeCount++
        return Promise.resolve(data)
      } else {
        return Promise.reject()
      }
    })
    const list = await Promise.all(promiseTasks)
    await privacyPhotoDB.batchInsert(list)

  }

  //删除图片
  async deletePhotos() {
    photoManager.deletePhotos(this.selectUris)
  }

  //根据相册名称获取图片
  async getAlbumPhotos(name: string) {
    const list = await photoManager.getAlbumPhotos(name)
    AlertDialog.show({ message: JSON.stringify(list, null, 2) })
  }

  // 导航右侧自定义菜单
  @Builder
  NavigationMenus() {
    Row() {
      Image($r("app.media.ic_public_camera"))
        .width(20)
        .aspectRatio(1)
        .onClick(() => {
          // TODO：拍照
          this.takePhoto()
        })
    }
    .height('100%')
    .padding({ right: 25 })
  }

  build() {
    Stack() {
      Navigation() {
        // 顶部选项卡
        Row() {
          Row() {
            ForEach(this.tabList, (item: tabItem, index: number) => {
              // TODO: 点击滑动动画，area 获取坐标
              Text(item.title)
                .layoutWeight(1)
                .textAlign(TextAlign.Center)
                .fontSize(12)
                .fontWeight(500)
                .height('100%')
                .fontColor($r('app.color.font'))
                .border({ width: 2, color: '#E4E4E6', radius: 10 })
                .backgroundColor(index === this.currentIndex ? $r('app.color.white') : Color.Transparent)
                .onClick(() => {
                  this.currentIndex = index
                })
            })
          }
          .width('100%')
          .height(32)
          .borderRadius(10)
          .backgroundColor('#E4E4E6')
        }
        .width('100%')
        .padding({
          left: 15,
          right: 15,
          top: 20,
          bottom: 20
        })

        // Tabs
        Tabs({ index: this.currentIndex }) {
          // 默认相册
          TabContent() {
            Scroll() {
              Column() {
                GridRow({ gutter: 2, columns: 4 }) {
                  ForEach(this.photos, (item: PhotoInfo) => {
                    GridCol() {
                      Stack({ alignContent: Alignment.TopStart }) {
                        Image(item.uri)
                          .width('100%')
                          .height('100%')
                          .objectFit(ImageFit.Cover)
                          .autoResize(true)
                          .interpolation(ImageInterpolation.Medium)
                        if (this.currentIndex == 0) {
                          Checkbox({ name: item.uri, group: 'group1' })
                            .margin({ left: 4, top: 4 })
                        }
                      }
                      .width('100%')
                      .aspectRatio(1)
                    }
                  })
                }

                // 占剩余高度
                Blank()
                  .layoutWeight(1)
              }
              .justifyContent(FlexAlign.Start)
            }
            .scrollable(ScrollDirection.Vertical)
            .height('100%')
          }

          // 用户相册
          TabContent() {
            Stack() {
              // 相册列表
              List() {
                ForEach(this.albums, (item: AlbumInfo) => {
                  ListItem() {
                    Row({ space: 10 }) {
                      Image(item.coverUri)
                        .height(70)
                        .aspectRatio(1)
                      Column({ space: 10 }) {
                        Text(item.albumName)
                          .fontSize(16)
                          .fontColor($r('app.color.font'))
                        Text(item.imageCount?.toString())
                          .fontSize(16)
                          .fontColor($r('app.color.font_sub'))
                      }
                      .alignItems(HorizontalAlign.Start)
                      .layoutWeight(1)

                      Image($r('app.media.ic_public_arrow_right'))
                        .width(20)
                        .height(20)
                        .fillColor($r('app.color.font_sub'))
                    }
                    .padding(10)
                    .onClick(() => {
                      //根据相册->获取图片
                      this.getAlbumPhotos(item.albumName)
                    })
                  }
                })
              }
              .divider({ strokeWidth: 1, color: $r('app.color.border') })
              .width('100%')
              .height('100%')

              Scroll() {
                Column() {
                  GridRow({ gutter: 2, columns: 4 }) {
                    ForEach(this.albumPhotos, (item: PhotoInfo) => {
                      GridCol() {
                        Stack({ alignContent: Alignment.TopStart }) {
                          Image(item.uri)
                            .width('100%')
                            .height('100%')
                            .objectFit(ImageFit.Cover)

                          if (this.isShowUserAlbumPhoto && this.currentIndex == 1) {
                            Checkbox({ name: item.uri, group: 'group2' })
                              .shape(CheckBoxShape.CIRCLE)
                              .margin({ left: 4, top: 4 })
                          }
                        }
                        .width('100%')
                        .aspectRatio(1)
                      }
                    }, (item: PhotoInfo) => item.uri)
                  }

                  // 占剩余高度
                  Blank()
                    .layoutWeight(1)
                }
                .justifyContent(FlexAlign.Start)
              }
              .scrollable(ScrollDirection.Vertical)
              .height('100%')
              .backgroundColor($r('app.color.white'))
              .visibility(this.isShowUserAlbumPhoto ? Visibility.Visible : Visibility.None)
            }
          }
        }
        .barHeight(0)
        .layoutWeight(1)
        .scrollable(false)

        // 操作栏
        Column() {
          Row() {
            Text('加密到相册：')
              .fontSize(14)
              .fontColor($r('app.color.font2'))
            Row() {
              Text('我的相册')
                .fontSize(14)
                .fontColor($r('app.color.brand'))
              Image($r('app.media.ic_arrow_right_large'))
                .width(20)
                .aspectRatio(1)
            }
          }
          .justifyContent(FlexAlign.SpaceBetween)
          .width('100%')
          .padding({ top: 15, bottom: 15 })
          .border({ width: { bottom: 1 }, color: $r('app.color.border') })

          Row({ space: 15 }) {
            Column() {
              if (this.currentIndex === 0) {
                CheckboxGroup({ group: 'group1' })
                  .onChange((value) => {
                    this.selectUris = value.name
                  })
              } else {
                CheckboxGroup({ group: 'group2' })
                  .onChange((value) => {
                    this.selectUris = value.name
                  })
              }
              Text('全选')
                .fontSize(14)
                .fontColor($r('app.color.font2'))
            }

            Button('下一步')
              .type(ButtonType.Normal)
              .borderRadius(10)
              .backgroundColor($r('app.color.brand'))
              .layoutWeight(1)
              .enabled(this.selectUris.length > 0)
              .onClick(() => {
                // TODO：选中后下一步, 加密照片
                this.copyPhotosToPrivacy()
              })
          }
          .layoutWeight(1)
          .alignItems(VerticalAlign.Center)
        }
        .height(126)
        .padding({ left: 15, right: 15 })
        .backgroundColor($r('app.color.white'))
      }
      .title('添加照片 ' + (this.selectUris.length > 0 ? `(${this.selectUris.length}张)` : ''))
      .titleMode(NavigationTitleMode.Mini)
      .mode(NavigationMode.Stack)
      .menus(this.NavigationMenus())

      // 加密结果页
      Navigation() {
        Stack({ alignContent: Alignment.Bottom }) {
          Column() {
            // 内容
            Column({ space: 20 }) {
              Image($r('app.media.ic_privacy_done'))
                .height(120)
                .fillColor($r('app.color.white'))
              Text(this.completeCount.toString() + '/' + this.selectUris.length + ' 张 照片/视频 已加密')
                .fontSize(16)
                .fontColor($r('app.color.white'))
            }
            .margin({ top: 200 })
          }
          .height('100%')

          Column({ space: 10 }) {
            Button('删除照片原图')
              .type(ButtonType.Normal)
              .borderRadius(10)
              .backgroundColor($r('app.color.white'))
              .fontColor($r('app.color.danger'))
              .width('100%')
              .onClick(() => {
                // TODO：删除照片原图
                this.deletePhotos()
              })
            Button('完成')
              .type(ButtonType.Normal)
              .borderRadius(10)
              .backgroundColor($r('app.color.white'))
              .fontColor($r('app.color.brand'))
              .width('100%')
              .onClick(() => {
                // TODO：关闭加密界面
                router.back()
              })
          }
          .margin({ left: 20, right: 20, bottom: 20 })
        }
        .height('100%')
      }
      .title(NavigationTitleBuilder('隐私空间'))
      .hideBackButton(true)
      .titleMode(NavigationTitleMode.Mini)
      .mode(NavigationMode.Stack)
      .linearGradient({
        angle: 213,
        colors: [[$r('app.color.brand'), 0], [$r('app.color.brand_light'), 1]]
      })
      .visibility(this.isEncrypting ? Visibility.Visible : Visibility.None)
    }
  }
}