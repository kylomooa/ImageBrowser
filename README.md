
## 使用WDImageView创建image，设置原图url与缩略图url即可
```
let imageView = WDImageView()
imageView.setImage(imageUrl: url, thumbnailUrl: url)
```

<image src="https://github.com/kylomooa/ImageBrowser/blob/master/imageBrowser.gif">
  
 ### 注意！请将同一组WDImageView添加在同一个superView上，并保持正确的顺序

