------
title: 解决JPEG图片横着显示的问题
author: zayfen
date: 2019/10/10
tags: 
 - canvas
 - jpeg
archives: 
 - web
categories: 
 - web
------
## 解决JPEG图片横着显示的问题
> 作者： 张云峰

背景： 一些jpeg图片，在pc中用图片查看器打开是正的，但是放到浏览器中，就横着了。今天，我们就来解决这个问题。

### 为什么JEPG图片会横着显示？
首先，我们看一个github上的一个关于此问题的issue： 
[https://github.com/GoogleChromeLabs/squoosh/issues/299](https://github.com/GoogleChromeLabs/squoosh/issues/299)
这个问题讨论的是chrome显示jpeg图片，旋转了90度的问题。
为什么会旋转呢？因为JEPG图片的EXIF data中有一个控制旋转的属性**Orientation**，但是有一些应用程序显示图片的时候会忽略这个属性，就导致图片在一些应用程序中显示出来和原本的方向不一致。

这里有一张JEPG图片的EXIF数据（可以看到第一个属性就是 Orientation）：
![JPEG图片的EXIF数据](https://res.cloudinary.com/zayfen/image/upload/v1570695926/img/ibvnab25sqxnz4ahapu6.png)


### 让图片永远都正着显示

因为 JPEG的 **Orientation** 属性被忽略了，那么当检测到图片Orientation的值表示需要旋转的时候，我们就主动将JPEEG图片旋转，并且改正或者去掉新图片的**Orientation** 字段。

```javascript

// 旋转图片的工具,(旋转之后的图片的EXIF data被移除)

 function fileToBuffer (file) {
      // 读取图片数据
      return new Promise(function (resolve, reject) {
        var reader = new FileReader()
        reader.onload = function(evt) {
          if (this.result instanceof ArrayBuffer) {
            // resolve(new Uint8Array(reader.result))
            resolve(this.result)
          }
        }
        reader.readAsArrayBuffer(file)
      })
    }
    function rotateImage(file){
      return new Promise((resolve, reject) => {
        fileToBuffer(file).then((binaryFile) => {
          let meta = EXIF.readFromBinaryFile(binaryFile)
          let orientation = meta.Orientation
          let formData = new FormData()
          let rotationMap = { 3: 180, 6: 90, 8: 270 }  // 3. 6， 8 分别表示旋转 180度，90度，270度
          //  没有读到EXIF数据，或者Orientation属性值表示不需要旋转，修直接返回数据
          if (meta === false || !rotationMap[orientation]) {
            formData.append('file', file, 'face.jpeg')
            return resolve({ base64: '', formData: formData, rotated: false })
          }
          
          let rotationDegree = 0
          let targetWidth = 200
          rotationDegree = rotationMap[orientation] || 0
          let image = document.createElement('img')
          image.onload = function () {
            var canvas = document.createElement('canvas')
            let ctx = canvas.getContext('2d')
            
            let rate = Math.min(targetWidth / image.width, 1)
            let imageWidth = image.width * rate
            let imageHeight = image.height * rate
            canvas.width = canvas.height =  Math.max(imageWidth, imageHeight)
            ctx.fillStyle = 'rgba(255, 255, 255, 0)'
            ctx.clearRect(0, 0, canvas.width, canvas.height)
            ctx.save()
            ctx.fillRect(0, 0, canvas.width, canvas.height)
            ctx.translate(canvas.width / 2, canvas.height / 2)
            ctx.rotate(rotationDegree * Math.PI / 180)
            ctx.drawImage(image, -canvas.width / 2, -canvas.height / 2 + (canvas.height - imageHeight) / 2, imageWidth, imageHeight)
            ctx.restore()
            canvas.toBlob((blob) => {
              formData.append('file', blob, 'face.jpeg')
              let base64 = canvas.toDataURL('image/jpeg', 0.8)
              console.log('rotated image  blob: ', blob)
              resolve({ base64: base64, rotated: true, formData: formData })
            }, 'image/jpeg', 0.8)
          }
          image.src = URL.createObjectURL(file)
        })
      })
    }

```


**例子效果：**
![旋转图片的例子](https://res.cloudinary.com/zayfen/image/upload/v1570701062/img/xfol8p1pqxdt4srgpsi2.png)






