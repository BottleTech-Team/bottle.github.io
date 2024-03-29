------
title: 如何用Chrome调试微信web页面
author: zayfen
date: undefined
tags: 
 - wechat
 - chrome
 - debug
archives: 
 - web
categories: 
 - web
------
> 作者： 张云峰

## 如何用Chrome调试微信web页面
> 微信调试有官方的微信开发者工具，这个工具很方便，但是有一个不方便就是调试公众号页面的时候，需要公众号给你授予开发者权限，
> 但是有的时候，你仅仅只是想调试页面的样式和一些dom结构，这个时候直接用chrome调试微信web页面就显得特别方便了。

### 步骤（此处仅仅在android手机上做了测试）

#### 1. 打开android手机的开发者模式 和 usb调试
> 每个手机打开方式都不一样，请自行搜索解决方案

#### 2. 打开chrome的 `Remote Devices`
![](https://res.cloudinary.com/zayfen/image/upload/v1566456083/img/xfln0smfyyrmta2cgfbg.png)

#### 3. 手机连接电脑
> 手机连接电脑的时候，会弹出一个usb授权提示弹窗，点解`确定`

#### 4. 在Chrome上的 `Remote Devices`上查看链接的手机情况
![](https://res.cloudinary.com/zayfen/image/upload/v1566456090/img/sebny1fdphicnkfmisgx.png)

#### 5. 调试手机上的页面
> 点击要调试的页面的右边的 `Inspect`按钮，就可以打开进行调试了。 **但是这个时候我们发现仅仅只能看到浏览器的页面，没有看到微信的web页面**

#### 6. 手机微信打开 http://debugx5.qq.com, 并勾选 `打开TBS内核Inspector调试功能`
![](https://res.cloudinary.com/zayfen/image/upload/v1566456094/img/xa7exyod0yyavarj1w7f.jpg)
> 勾选后会提示重启，点击确定就行

#### 7. 微信上打开要调试的web 页面，就可以在chrome中看到了
![](https://res.cloudinary.com/zayfen/image/upload/v1566456098/img/nz3ismpqljduymsinjq0.jpg)
![](https://res.cloudinary.com/zayfen/image/upload/v1566456100/img/fo5afmbyo4uvj7qgrgop.png)

#### 8. 点击chrome中 `inspect`按钮及可以开始调试了
![](https://res.cloudinary.com/zayfen/image/upload/v1566456105/img/irjrryrjdx9eq0rqg7pb.png)


