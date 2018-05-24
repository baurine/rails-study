# Rails Misc Note

会记录一些 rails 项目中遇到的比较常见的问题及解决方法。

1. gem & bundle
1. rvm & gemset
1. sort by associate count
1. 多态 (Polymorphic)
1. ActiveRecord 的一些补充
1. migration 的教训
1. index 的重要性
1. 在本地跑 production
1. asset pipeline / sprockets
1. render js / pjax / turbolinks
1. 在 controller 中使用 view 方法
1. `find_in_batches` & `find_each`
1. 在路由中使用 constraints
1. jquery-rails & jquery-ujs & rails-ujs

## gem & bundle

查看一个项目中 gem 安装在何处：

    $ gem which [gem_name]
    $ bundle show [gem_name]

例如：

    $ gem which capistrno
    ---/.rvm/gems/ruby-2.3.0/gems/capistrano-3.9.0/lib/capistrano.rb
    $ bundle show capistrano
    ---/.rvm/gems/ruby-2.3.0/gems/capistrano-3.9.0

通过 gem help 查看 gem 的命令：

    $ gem help
    $ gem help commands

其它一些有用的命令：

    # 查看已安装的 gem
    $ gem list

    # 查看 ruby 的环境变量
    $ gem env

    # 这个命令有意思，启动一个 http 服务器查看已安装的所有 gem 的信息
    $ gem server

升级 Gemfile 中的某个 gem：

    $ bundle update gem_name

## rvm & gemset

rvm 用来管理 ruby 版本，gemset 是 rvm 的功能之一，用来管理 gem 包版本。rvm 官网 [rvm.io](https://rvm.io/)

rvm 其实跟 rails 没有什么关系，但 rvm 是 rails 开发中常用的工具之一。

新 clone 一个 rails 工程，需要指定 ruby 版本，且安装的 gem 不要影响现有的其它 rails 工程，该怎么做呢。

首先，进入当前工程目录，用 `rvm list` 列举当前系统安装的 ruby 版本：

    > rvm list

    rvm rubies

       ruby-1.9.3-p484 [ x86_64 ]
       ruby-2.2.0 [ x86_64 ]
    =* ruby-2.3.0 [ x86_64 ]
       ruby-2.3.2 [ x86_64 ]
       ruby-2.3.3 [ x86_64 ]

    # => - current
    # =* - current && default
    #  * - default

如果没有所需要的 ruby 版本，则用 `rvm install` 安装，安装之前可以用 `rvm list known` 查看一下当前都有哪些版本，然后从中选一个。

    > rvm install 2.4.1

如果已经安装了所需版本，但不是当前使用的版本，则用 `rvm use` 切换版本：

    > rvm use 2.4.1

用 `rvm current` 查看当前使用的 ruby 版本，当然用上面的 `rvm list` 也是可以的。

我们可以把目标版本号写到当前目录下的 `.ruby-version` 配置文件中，这样，每次进入这个目录时，就会自动切换到这个 ruby 版本，不需要我们再手动运行 `rvm use` 来切换。

    > echo '2.4.1' > .ruby-version

然后，我们创建一个 gemset 来存放此工程用到的所有 gem，一般 gemset 的名称为项目名称，或加上环境，比如 `myweb`，`myweb_staging`，`myweb_production`：

    > rvm gemset create myweb

然后，用 rvm gemset use 命令来切换到使用此 gemset：

    > rvm gemset use myweb

之后，运行 `bundle` 后所安装的 gem 就会放在此 gemset 所对应的目录中。

我们可以把 gemset 写到 `.ruby-gemset` 中，这样，每次进入这个目录时，就会自动切换到这个 gemset，不用再手动运行 `rvm gemset use` 命令。

    > echo 'myweb' > .ruby-gemset

需要注意的是，gemset 是与 ruby 版本号相关的，如果在 ruby 2.4.1 下创建，那么就只有在 ruby 2.4.1 下生效，如果切换了另一个 ruby 版本，这个 gemset 就不存在。所以，实际这个 gemset 的全名是 `2.4.1@myweb`，可以用 `rvm use` 命令一步到位，同时指定使用的 ruby 版本和 gemset：

    > rvm use 2.4.1@myweb

可以把 `.ruby-version` 和 `.ruby-gemset` 的内容写到一个配置文件 `.versions.conf` 中，格式如下：

    ruby=ruby-2.4.1
    ruby-gemset=myweb

当你使用了一个新的 gemset 后，你会发现，执行 `rails s` 或 `bin/rails s` 出错，提示 rails 不存在之类的错误，于是你继续 `bundle`，仍然提示 bundle 不存在。你感到一阵困惑后马上醒悟过来，因为使用了 gemset 后，所有的 gem 都从相应的 gemset 中取，而 rails 和 bundle 也是 gem，此时的 gemset 是空的，什么都没有，自然提示找不到 rails 和 bundle。

所以，新建 gemset 后，要重装先安装 bundler，再用 bundler 的 bundle 命令去安装其它 gem。

    > gem install bunlder
    > bundle

## sort by associate count

根据关联记录的数量来排序。比如有一个用户表 users 和评论表 reviews，有些用户可能有多个评论，有些用户没有评论。现在有一个显示所有用户及它的评论数的页面，要求可以按照评论数来对用户进行排序。

此时，如果用默认的 joins 即 inner join，会发现，那些评论数为 0 的用户不见了。怎么办呢，用 `left_joins`，如下所示：

    User.left_joins(:reviews)
        .group(:id)
        .order('count(reviews.id) desc')

注意，order 中的必须是 `count(reviews.id)` 或 `count(reviews.*)`，而不能是 `count(*)`，因为对于评论数为 0 的用户来说，`count(*)` 的结果是 1，而 `count(reviews.*)` 的结果才是正确的 0。

我也写了一部分解释在 [Postgresql Study Note](https://github.com/baurine/study-note/blob/master/database/postgresql-study-note.md) 中。

## 多态 (Polymorphic)

一般的文章讲多态只讲到 model 怎么写，忽略了 route 和 controller 该怎么写，找到了一篇讲解多态并包含 route 和 controller 的文章，可以认为是最佳实践：[Polymorphic Routes in Rails](http://thelazylog.com/polymorphic-routes-in-rails/)。(但这篇文章没有讲到 migration 该怎么写，我应该再写一篇文章，把二者结合起来)。

使用：<http://caok1231.com/rails/2014/10/13/many-to-many-and-polymorphic.html>

剩下的待补充。

## ActiveRecord 的一些补充

1. enum 的使用：[关于在 Rails Model 中使用 Enum (枚举) 的若干总结](https://ruby-china.org/topics/28654)

   ActiveRecord 是对 DB Table 的一层封装，属性和表中的列的类型并不完全相同。enum 声明的属性，在 ActiveRecord 中的类型是 String，在 table 中是 Integer，ActiveRecord 会自动完成类型的转换。

   一些补充：[Rails 中 Database table / ActiveRecord / ObjectType 关系](https://github.com/baurine/graphql-study/blob/master/notes/appendix.md)

1. jsonb 类型的列

   jsonb 类型的引入让 PostgreSQL 有了类似 MongoDB 的能力，可以在此类型的列中存入任意类型的值，别看它名字中有 json，实际并不是只能存 json 格式的内容。我试过了，存 Integer，String，Hash 等都是可以的。但是要记住，你用什么类型存进去的，取出来就要按这种类型处理。

## migration 的教训

结论：不要在 migration 中进行耗时过长的操作，应该让 migration 的时间尽可能短，把耗时的操作放到 rake task 中，之后自己 ssh 到服务器操作或用 capistrano 辅助。

起因：有一个 podcasts 的表，每个 podcast 有多个 episodes，现在要给 podcasts 表增加一列 `average_duration`，这个值是 podcast 的所有 episodes 的 duration 的平均值。

这个增加列的 migration 是很简单的：

    add_column :podcasts, :average_duration, :float

考虑到执行这个 migration 后，我们还要为这一列计算值，以往我是把这种事情放在 rake task 中做的，比如：

    task cal_podcast_average_duration: :environment do
      Podcast.order(id: :desc).each(&:cal_duration)
    end

这样，布署之后，我们还需要手动 ssh 到服务器上执行这个 task。

但这次，我想节省掉手动执行 task 这个步骤，想把这个事情放到 migration 中进行，这样，布署的时候就可以把这件事一块做了。

代码大致是这样的：

    def change
      add_column :podcasts, :average_duration, :float

      reversible do |change|
        change.up do
          Podcast.order(id: :desc).each(&:cal_duration)
        end
      end
    end

但是，由于疏忽，episodes 表中的 `podcast_id` 索引没做，而且由于数量巨大，这次的 migration 耗时漫长。这样导致的后果：

1. 布署过程中一旦网络中断，布署将失败。而如果放到 rake task 中做，虽然也很耗时，但我们可以在服务器上使用 tmux 来做这件事，不用担心网络中断问题。
1. 另外，如果放到 rake task，我们可以在布署后，给 episodes 表的 `podcast_id` 加上索引后，再执行这个 rake task，很灵活，但在 migration 中就不能这样做。

虽然问题是由索引引起的，但从这次事件中明白，migration 应该越快越好，布署也要越快越好，耗时操作放到 rake task 中进行。

## index 的重要性

意识到 index 的重要性是从上面的事件中感受到的。在没有为 episodes 表的 `podcast_id` 列加索引前，migration 耗时达一个多小时，每个 podcast 耗时数百毫秒，加索引后，仅耗时数毫秒，差距几百倍，最终耗时从一个多小时降到了几分钟。

平时怎么来注意这个索引的问题呢：

1. 看 production.log，看哪个 sql query 耗时
1. 用 `pg_top` 工具

## 在本地跑 production

涉及到两个问题，一是如何是在本地运行 production 环境，二是如何在 production 环境下能够用上 developement 数据库中的数据。

第一个问题的解决方案：[How to Run a Rails App in Production Locally](https://gist.github.com/rwarbelow/40bd72b2aee8888d6d91)

其中最关键的一步是在启动 server 之前，先执行预编译 `bin/rake assets:precompile`，提前生成 assets 文件，这也是 development 和 production 环境最大的区别了。

第二个问题，数据的问题，一种解决办法是把 development 的数据库拷贝一份生成 production 数据库，但我并没有尝试，因为另一种方法更简单，直接修改 database.yml，设置 production 环境下直接使用 development 环境的数据库。

    # config/database.yml
    development:
      adapter: postgresql
      database: podknife_development
    production: &PROD
      adapter: postgresql
      database: project_development

## asset pipeline / sprockets

- [Ruby on Rails 实战圣经 - Asset Pipeline](https://ihower.tw/rails/assets-pipeline-cn.html)
- [RailsCasts #279 - Understanding the Asset Pipeline](http://railscasts.com/episodes/279-understanding-the-asset-pipeline)

在 Rails 中常说的 asset pipeline 和 sprockets 基本上指的是一件事，asset pipeline 指的是一种技术，而 sprokcets 是实现这种技术的 gem。

在生产环境下，asset pipeline 会把 app/assets/javascripts/application.js 中 require 的所有 js 文件 bundle 到 applicaton-[hahd].js 中，把 app/assets/stylesheets/application.css 中 require 或 import 的所有 css 文件 bundle 到 application-[hash].css 中。

在 bundle 时候，sprockets 会根据文件后缀，从右往左，依次调用相应的预处理进行处理，比如 test.js.coffee.erb，依次调用 ruby, coffee, js 预处理器进行处理，最终生成 js 代码，test.css.scss.erb，依次调用 ruby, sass, css 预处理器进行处理，最终生成 css 代码。

这个和目前前端的打包工具 Webpack 所做的工作类似。而且从 Rails 5.2 开始，Rails 内置了 Webpacker，一定程度上削弱了 asset pipeline 的作用。

但 sprockets 的作用不只在于处理 asset pipeline，它还用在 render view 中，比如 render 一个 index.html.haml 文件，sprockets 会依次调用 haml, html 预处理器，并最终生成 html 代码。

sprockets 提供了 `rake assets:precompile` task 来进行 bundle，`rake assets:clean` task 用来清除 bundle。一般需要布署到生产环境时才需要进行 bundle。

在开发环境下，application.js 中 require 的 js 文件或库不会 bundle 到一个文件中，而是每一个 require 都单独 bundle 到一个文件中，比如 application.js 是这样的：

    //= require jquery
    //= require jquery_ujs
    //= require turbolinks
    //= require_tree .

就会生成四个 js 文件，分别是 jquery.js, jquery_ujs.js, turbolinks.js, application.js。

## render js / pjax / turbolinks

- [在 Rails 中使用 JavaScript](https://ruby-china.github.io/rails-guides/v4.1/working_with_javascript_in_rails.html)
- [HTML5 简介 (三)：利用 History API 无刷新更改地址栏](https://www.renfei.org/blog/html5-introduction-3-history-api.html)
- [PJAX 的实现与应用](http://www.cnblogs.com/hustskyking/p/history-api-in-html5.html)
- [Ruby on Rails 实战圣经 - Ajax 应用程式](https://ihower.tw/rails/ajax-cn.html)
- [RailsCasts #294 - Playing with PJAX](http://railscasts.com/episodes/294-playing-with-pjax)
- [RailsCasts #390 - Turbolinks](http://railscasts.com/episodes/390-turbolinks)

这三种技术的相同点：

- 都是 ajax 请求

不同点：

- render js - 返回的是 js 代码，客户端得知响应是 application/javascript 类型，就执行它。
- pjax - HTML5 pushState + AJAX，客户端得到的是 HTML 代码，而且是 HTML 片断，然后客户端用这个片断替换旧的片断内容，同时用 HTML5 pushState API 修改 url。
- turbolinks - 相比 pjax，turbolinks 的 ajax 请求，得到的是完整的 HTML 文档，然后客户端会检测 `<head>` 部分是不是和上一个页面的 `<head>` 相同，如果相同，就不再解析 javascript 和 css 链接，直接用新的 `<body>` 替换旧的 `<body>`，节省了重新解析和下载 javascript 和 css 的时间，加快了加载速度，同时和 pjax 一样，用 HTML5 pushState API 修改 url，但是如果 `<head>` 部分完全不一样，那么就会整体替换 `<html>`。

在 rails view layout 中，对 link 加上 `remote: true` 属性 (将会转成标签的 data-remote 属性)，点击链接后，默认的跳转行为将会变成发送普通的 ajax 请求。服务端收到 ajax 请求后，可以 render json 给客户端返回 json，也可以 render js 给客户端返回一段 js 代码。客户端可以通过 response header 中的 Content-Type 取得响应的类型，如果是 application/json 则解析成 json，如果是 application/javascript，则执行它。

为什么加上加上了 data-remote 属性的链接，点击后就会变成发 ajax 请求了呢，这是因为 rails 使用了 `jquery_ujs` 库 (在 rails 5.1 后，rails deprecated 了 jQuery，不再默认使用 jQuery 了，所以这个库变成了 `rails_ujs`)，这个库会给所有带 data-remote 属性的链接加上 onclick 事件，在 onclick 事件中取消默认的跳转行为，改成发送 ajax 请求。

pjax 也需要用专门的 js 库来实现，这个库的作用是，给所有带 data-pjax 属性的 `<a>` 标签加上 onclick 事件，在 onclick 事件中，使用 `e.preventDefault()` 取消默认的跳转行为，改成发送 ajax 请求，而且不是普通类型的 ajax，是 pjax 类型的 ajax，一般会在 request header 中使用 `X-PJAX: true` 来表明这是 pjax 类型的 ajax，服务端收到此类型的 ajax 请求后，返回 HTML 片断，客户端用新的 HTML 片断替代旧的 HTML 片断，并更新 url。

turoblinks 同样需要用专门的 js 库来实现，它的工作和 pjax 库类似，给所有没有声明 data-no-turbolink 属性的 `<a>` 标签加上 onclick 事件，在 onclick 事件中，取消默认跳转行为，改为发送 turbolinks 类型的 ajax 请求，并处理 ajax 请求的响应，解析返回的 HTML 的整个文档，根据 `<head>` 部分的内容选择只替换 `<body>` 还是替换整个 `<html>`，并更新 url。

使用了 trubolinks 后对原来 js 逻辑最大的改变是就是要用 `turbolinks:load` 事件替换 `$(document).ready()` 事件。

## 在 controller 中使用 view 方法

参考：

- [Using helper methods inside your controllers](https://medium.com/little-programming-joys/using-helper-methods-inside-your-controllers-51dd5e39ee72)

示例：

    @query = ActionController::Base.helpers.sanitize(params[:q])

## `find_in_batches` & `find_each`

参考：

- [`find_in_batches`](http://api.rubyonrails.org/classes/ActiveRecord/Batches.html#method-i-find_in_batches)

写了一个 task，对一个有超过 90 万条记录的表的每一个记录进行操作，结果每次跑到 30 万条时，机器内存耗尽，系统就把 rails 进程杀掉了。代码大概是这样的：

    desc 'update episodes'
    task update_episodes: :environment do
        Episode.all.each do |ep|
            ep.update(...)
        end
    end

我正准备改程序让它每次只操作 30 万条记录，老板推荐我使用一个方法叫 `find_in_batches`，第一次听说这个方法，一试，果然好用，故记录在此。

修改后代码如下：

    desc 'update episodes'
    task update_episodes: :environment do
        Episode.find_in_batches(batch_size: 10000) do |group|
            sleep(50)
            group.each do |ep|
                ep.update(...)
            end
        end
    end

后来在看别人的代码时发现还有一个类似的方法：`find_each`，其实没有太大差别，前者可以设定 `batch_size` 参数，后者固定是 1000。相当于后者是前者的一个封装。使用上略有区别，前者传到 block 中的是一个 array，后者是具体的 object。

    Person.find_each(:conditions => "age > 21") do |person|
        person.party_all_night!
    end

## 在路由中使用 constraints

起因，HomeController 中混杂了太多功能，导致代码庞大。它包括以下功能：

1. 展示首页，包括随机推荐内容，最近添加内容，最多人访问内容等，路由是 `/`
1. 搜索功能，路由是 `/?q=xxx`
1. 搜索提示功能，路由是 `/?q=xxx&hint=1`

想把它们拆分到不同的 controller 中，但是它们的 path 是一样的，只是查询参数不一样，那怎么设置路由呢，用 constraints。示例如下：

    # routes.rb
    get '/', to: 'search_hints#index', constraints: lambda { |req| !req.query_parameters['hint'].nil? }
    get '/', to: 'search#index', constraints: lambda { |req| !req.query_parameters['q'].nil? }
    root 'home#index'

## jquery-rails & jquery-ujs & rails-ujs

- [jquery-rails](https://github.com/rails/jquery-rails)
- [jquery-ujs](https://github.com/rails/jquery-ujs)
- [rails-ujs](https://github.com/rails/rails-ujs/tree/master)

我们一步步来解释这些东西。

首先，jquery-rails 是一个 gem，后二者是独立的 js 库。

在 rails 拥抱 webpacker 之前，如果想在 rails 中使用一些开源的第三方 javascript 库，除了直接把它们的文件拷过来之外，还有一种用法，就是把这些 js 以及配套的 css/assets 等包装成一个 gem，然后你就可以方便地使用 bundler 来安装这个 gem，从而导入相应的 javascript 库。

安装这些 gem 后，你还需要在 application.js 和 application.css 中手动声明导入相应的 js 库和 css 文件。

比如 jquery-rails 这个 gem 就包装了 jQuery 这个 js 库。安装了这个 gem 后，就可以在 application.js 中声明使用 jQuery 这个 js 库。

    // application.js
    //= require jquery

同时，jquery-rails 还包装了另一个基于 jQuery 实现的库：jquery-ujs。

jquery-ujs 是干什么用的呢，它主要是用来给一些 DOM 添加一些额外的很有用的功能，使用 `data-*` 属性。比如你给一个 button 添加一个 `data-disable="true"` 的属性，这个按键按下后，一定时间内就不能再点击了，以消除抖动，给 form 元素加上 `data-remote="true"` 的属性后，这个 form 的提交就变成了 ajax 请求，而不再是普通请求。

更加详细的功能介绍：[A definitive guide to Rails’s unobtrusive JavaScript adapter](https://m.patrikonrails.com/a-definitive-guide-to-railss-unobtrusive-javascript-adapter-ef13bd047fff)

以及看官方文档。

我们也需要在 applicaiton.js 中声明导入这个 js 库。

    // application.js
    //= require jquery
    //= require jquery_ujs

[Rails Assets](https://rails-assets.org/#/) 这个网站提供了将 js 库封装成 gem 的功能，同时提供检索，你可以在这里搜索别人有没有封装过你想用的 js 库，如果有，就直接拿来用，否则你就要自己封装了。

然后从 rails 5.1 开始，rails 开始拥抱 webpack，把 webpack 这个工具封装成了 wepbacker gem 并集成到了 rails 5.1 中，并放弃了对 jQuery 的默认使用和依赖。但 `jquery_ujs` 这个这么好用的库是依赖 jQuery 的呀，那怎么办呢，重写呗，于是 rails 把 `jquery_ujs` 用 DOM 原生 API 重写了，这样就不用依赖 jQuery 了，并改名为 `rails-ujs`，同时也把它用 gem 封装了一下以方便在 rails 中使用，封装好的 gem 也叫 `rails-ujs`。

所以你要使用 rails-ujs 的话，三步：

    // Gemfile
    gem 'rails-ujs'

    // command line
    $ bundle

    // application.js
    //= require rails_ujs

或者如果想在 npm 中使用，直接用 `npm install rails-ujs --save`。

参考链接：[Rails 5.1 has dropped dependency on jQuery from the default stack](https://blog.bigbinary.com/2017/06/20/rails-5-1-has-dropped-dependency-on-jquery-from-the-default-stack.html)

但由于 `rails-ujs` 是如此的基础，几乎是 rails 的标配，所以后来 rails 干脆把它深度集成到 rails 的源码中了，这样，`rails-ujs` 其实不完全不需要了，因为新的 rails 中已经内置了它的所有功能。(有待确认是不是完全不需要自己手动 `require rails_ujs` 了)

> rails-ujs was [moved into Rails itself](https://github.com/rails/rails/commit/ad3a47759e67a411f3534309cdd704f12f6930a7) in Rails 5.1.0.
