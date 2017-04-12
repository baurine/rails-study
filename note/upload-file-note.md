# Upload File Note

Upload files in rails by CarrierWave gem and jQuery File Upload plugin.

## References

1. [CarrierWave](https://github.com/carrierwaveuploader/carrierwave)
1. [jQuery File Upload Basic](https://github.com/blueimp/jQuery-File-Upload/wiki/Basic-plugin)
1. [Ruby on Rails - File Uploading](https://www.tutorialspoint.com/ruby-on-rails/rails-file-uploading.htm)
1. [Preview an image before it is uploaded](http://stackoverflow.com/questions/4459379/preview-an-image-before-it-is-uploaded)

## Note

首先，明确一点，这两个库只是辅助实现文件上传，文件上传的核心功能是由浏览器和 HTTP 服务器默认实现的。只要在一个 form 表单里放一个 type 为 file 的 input，选择文件后，点击 submit，文件就会由浏览器自动上传到服务器，服务器在将文件接收完成后，将文件存在一个默认的目录下，然后再进入到指定的路由方法中。

如果不用 CarrierWave，在对应的路由方法中，我们需要手动将这个文件从默认目录下转存到我们的目标目录下，并更新数据库中 model 对应的记录。而 CarrierWave 就是帮助我们自动实现这些功能的，当然，它还是一些其它强大的功能。

如果仅仅使用 CarrierWave，那么文件上传过程，客户端是无法知道进度的，用户会不知道在发生什么，这样的用户体验是很差的。而且，删除某个文件的做法，CarrierWave 的建议是增加一个 `remove_xx` 的 checkbox input，这样的用户体验更是无法接受。而 jQuery File Upload 就是用来改善客户端的这个问题的，它在客户端使用 ajax 请求上传文件，可以得到进度的回调，并且在上传完成后可以让服务端返回文件的 url，如果是图片的话，就可以上传完成后马上预览，如果有错误，也可以让服务器以 json 的形式返回然后马上展示出来。

所以 CarrierWave 和 jQuery File Upload 是相互独立的，CarrierWave 用于辅助服务端，jQuery File Upload 用于辅助客户端。两者可以独立使用，但配合使用效果更佳。

CarrierWave 的使用很简单，网上也有很多介绍，没有遇到什么大问题。

1. CarrierWave 在使用文件缓存功能时，不管文件最终是存储在当前服务器还是其它文件存储服务器 (比如 Amazon S3)，缓存都是存储在当前服务器上，且 `cache_dir` 设不设置都可以，默认在 `storage_dir` 的根目录下的 tmp 目录。

jQuery Upload File 就不一样的，首先文档组织得太差，看了半天连需要哪些文件都不清楚。其次，没有哪个地方说明到，当这个 plugin 操作一个在 form 中的 file input 时，它会把 form 里其它所有 input 也一块 post 到服务器，我之前一直以为这个 plugin 只会影响到单个 file input，所以在看一些 CarrierWave 结合这个 plugin 的 sample 时，怎么也看不明白，为什么不需要为这个操作新增一个单独的路由。

所以目前为止收获的一些 jQuery Upload File plugin 的使用经验：

1. 如果只需要用到这个 plugin 最核心的上传功能，只需要 jquery.fileupload.js 和 jquery-ui.min.js 2 个文件，前者依赖后者，前者来自这个 plugin 的源代码，后者我从别的项目中拷过来的。
1. 这个 plugin 工作时，即选中文件上传时，会把整个 form 一块上传，相当于点击了 form 的 submit 一样。这是个坑啊。理想情况应该是只上传这个 file。

CarrierWave 和 jQuery File Upload 配合使用的最佳姿势 (Demo 还未实现，待实现)：

1. jQuery File Upload 选择文件后，上传到服务器，在单独的路由方法中，将上传的文件先 cache 住，并以 json 的形式向客户端返回 cache 住的 url 及 cache_name，如果上传的图片，那么客户端就可以通过这个 url 预览上传的文件；
1. 客户端得到 `cache_name` 后，把它的值赋值给 form 中 hidden 的 input，点击 form 的 submit 时，重新把 `cache_name` 上传到服务端，服务端通过 `cache_name` 从 cache 中重新得到这个文件，同时，点击 submit 时，要把这个 file 的 input 从 form 中移除，避免文件的重复上传。
