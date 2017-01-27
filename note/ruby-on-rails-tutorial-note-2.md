# Ruby on Rails Tutorial Note 2

Note for the book [*Ruby on Rails Tutorial*](https://www.railstutorial.org/book).

## Sample

![](./art/1_simple_blog.png)

## Note

2016/8/5，重新学习。

- 跳过第一、二章，从第三章 sample app 的例子开始。
- 跳过第四章 ruby 部分，这个已经掌握了。
- 跳过第十一章，激活账户部分。
- 跳过第十二章，找回密码部分，没有服务器可测试。

### 第 3 章 基本静态界面

测试：TDD

测试类型：控制器测试、模型测试、集成测试

    $ rails test

TDD: 遇红 --> 变绿 --> 重构

测试中定义的 `setup` 方法会在每次测试前自动调用。

在 erb 中配套使用 `provide(:title, "Home")` ， `yield(:title)`。
只有在 erb 中才需要使用 provide，因为在 controller 中定义的实例变量可以在 view 中直接使用，不需要用 yield 来获取。

高级测试技术：监控文件修改并自动运行测试，略，暂时不用。

### 第 4 章 ruby

在 helper 中自定义 helper 方法，helper 方法可以在 controller 和 view 中使用。

(看似 ruby & rails 的喜欢用 unix 的命令方式命名函数名和变量，而不是 camel 式，比如使用 `base_title`，而不是 baseTitle)

### 第 5 章 完善布局

完善布局，使用 boostrap-sass gem 包引入 boostrap css。

局部视图。以下划线 `_` 开头。

#### 5.2 Sass 和 Asset Pipeline

- 预处理器将所有的 css 合并到 application.css 中，将所有的 js 合并到 applicaiton.js 中。
- 根据后缀名使用不同的预处理器。
- 三个最常用的后缀：Sass 的 .scss 文件，CoffeScript 的 .coffee，ERB 文件的 .erb。

#### 5.3 链接

具名路由

#### 5.4 使用集成测试

    $ rails g integration_test site_layout

(集成测试和控制器测试的区别?)

### 第 6 章 用户建模

创建，保存，销毁，更新

    User.new({}), user.save
    User.create({}) = new + save
    user.destroy
    user.reload
    user.update_attributes({})

查找：`User.find(id), User.find_by(key: value)`

#### 6.2 验证用户数据

为模型增加约束规则。重要的一环。
存在性、长度、格式、唯一性、二次确认。

对模型使用 TDD 进行有效性测试。

验证出错后的错误信息：`user.errors.full_messages`

Active Record 中的唯一性验证无法保证数据库层也能实现唯一性!!! 解决办法，在数据库层也加上唯一性限制。

在数据库中为 email 先创建索引，再为索引加上唯一性限制。

    before_save { self.email = email.downcase }

为什么左边要使用 self，而右边不需要。如果左边省略 self，就变成了 `email = email.downcase`，这个 email 就会变成局部变量，语义就变了，而右边省略 self 并不会必变语义。

#### 6.3 添加安全密码

只需要一个 `has_secure_password` 的方法即可，添加这个方法，自动获取以下功能：

- 在数据库中的 `password_digest` 列存储安全的密码哈希值。
- 获得一对虚拟属性，password 和 `password_confirmation`，而且创建用户对象时会执行存在性验证和匹配验证。
- 获得 authenticate 方法, 如果密码正确, 返回对应的用户对象,否则返回false。

`user.authenticate(password)`，参数是明文密码，如果明文密码正确的话，返回 user 本身。使用 `!!` 将结果转换成 true / false。

`!!` 会把对象转换成相应的布尔值。nil 转换成 false，其余转换成 true。

`has_secure_password` 发挥功效的唯一要求是，对应的模型中有个名为 `password_digest` 的属性。

    $ rails g migration add_password_digest_to_users password_digest:string

同时，要使用 bcrypt gem。

### 第 7 章 注册

调试：

    <%= debug(params) if Rails.env.development? %>

三种环境： development, test, production

调试器：byebug

在代码中加上 debugger，就会在此处设置断点。

#### 7.2 注册表单

`form_for` 的使用

#### 7.3 注册失败

用 `<li>` 显示所有错误信息

健壮参数，避免安全问题，比如用户多传一个 `admin=1`，如果不用健壮参数，此用户就会被修改成 admin 账户。

#### 7.4 注册成功

create 动作并不对应视图，实际上，只有 get 请求才对应视图，post/patch/put/delete 都没有对应的视图，所以，views 里面只有 index / new / show / edit .html.erb

除 get 请求外的请求，repsonse 要么是 `redirect_to` 要其它 get 请求，要么是 render 另一个视图。

##### 7.4.2 闪现消息

      flash[:success] = "Welcome to the Sample App!"
      flash[:info] = "xxx"
      flash[:danger] 
      flash[:warning]

flash 相当于一个全局变量 (其实是方法)，在各个页面中需要自己从中读取值，使用适当的方法渲染在适当的地方，rails 并不会帮你渲染，就比如前面注册失败后，rails 只是帮你把错误信息存在 user.errors 里，怎么把它渲染出来是你自己的工作。

### 第 8 章 基本登录功能

#### 8.1 会话

session

登录 和 注册，对应到 rails 里的控制器，是完全不一样的，前者对应 Sessions 控制器，后者对应 Users 控制器。

登录界面，对应 `Sessions#new` 视图

注册界面，对应 `Users#new` 视图

flash.now 的使用：

- 普通的 flash 使用在 `redirect_to` 之前，flash 的内容在下次请求时仍然存在，然后再消失
- flash.now 使用在 render 之前。flash.now 的内容仅在此次请求时存在，下次请求时消失

#### 8.2 登录

哦，默认 helper 函数只可以在视图中使用，并不能在 controller 中使用，除非在 controller 中 include helper module。

在 ApplicationController 中 `include SessionsHelper` 后在所有的 controller 中都可以使用 SessionHelper 中的方法。

session 方法只创建临时 cookie，浏览器关闭后就没有了。
而 cookie 方法会创建持久 cookie。
cookie 在 header 中传送，请求时浏览器会自动带上放在 header 的 "Cookie" 字段。然后浏览器会根据 repsonse header 中的 "Set-Cookie" 和 "Set-Cookie2" 来更新 cookie。

在服务器端使用 `session[:user_id] = user.id` 保存 session 后，整个 session，所有的 key 和 value，作为一个整体，被统一加密，加密后的内容作为 `_micropost_web_session` 这个 key 的值，再形成一个整体，放在 header 的 Set-Cookie 字段，发送回浏览器。

浏览器发送新的请求时，带上上次得到的 cookie，发送回服务器，服务器取出 `_micropos_web_session` 的值，整体解密，解出一个 session 的 hash map，从中就有一对以 `user_id` 为 key 的键值对。

截图略。

http header 是一个复杂的数据结构，有 N 多层嵌套的键值对。

### 第 9 章 高级登录功能

持久化 cookie

生成创建持久 cookie 所需的记忆令牌 (remember token) (咦，这种令牌就跟 api 中的 token 是一样的作用啊)

1. 生成随机字符串，当做记忆令牌。
1. 把这个令牌存入浏览器的cookie中，并把过期时间设为未来的某个日期。
1. 在数据库中存储令牌的摘要。
1. 在浏览器的 cookie 中存储加密的用户 id。
1. 如果 cookie 中有用户的 id，就用这个 id 在数据库中查找用户，并且检查 cookie 中的记忆令牌和数据库中的哈希摘要是否匹配。

(嗯，这个流程和 api 的例子差不多，api 的例子中，把 token 和 email 放在 header 中，服务器端从 header 中取到 email 和 token，先用 email 找到用户，再验证 token 是否一致，这里更严谨一些，验证的是 token 的摘要，而且没有使用 email，而是使用了 id)

(另外，当要修改用户信息时，目标用户 id 必须与当前登录 id 一致)

截图略。

向客户端返回 cookie 时，每一条 cookie 都有在 response header 里一个单独的 Set-Cookie 字段。
而所有的 session 都在同一条 Set-Cookie 中。

login / logout 的调用路径：

首先, login / logout 的动作路由到 SessionsController 中，分别路由到 create / destroy 中，然后，在这些方法中调用 SessionsHelper 中的 `log_in / remember / log_out` 等方法，而 SessionsHelper 中的方法又会调用到 User model 中的方法。

SessionController --> SessionHelper / User model --> User model

### 第 10 章 更新，显示，删除用户

只有自己才能更新自己的信息。

增加身份验证机制。

#### 10.1 更新用户

edit 和 new 的界面几乎一样，可以复用代码。

> 还有一个细节需要注意一下，代码清单 10.2 和代码清单 7.14 都使用了相同的 `form_for(@user)` 来构建表单，那么 Rails 是怎么知道创建新用户要发送 POST 请求,而编辑用户时要发送 PATCH 请求的呢? 这个问题的答案是，通过 Active Record 提供的 `new_record?` 方法检测用户是新创建的还是已经存在于数据库中。

(原来如此!)

`target="_blank"`，表示在新窗口中打开

#### 10.2 权限系统

> 身份验证系统的功能是识别网站的用户，权限系统是控制用户可以做什么操作。

本节我们要实现一种安全机制，限制用户必须先登录才能更新自己的资料，而且不能更新别人的资料。

##### 10.2.1 必须先登录

`before_action` 过滤器。(真可惜，android / iOS 这样的客户端开发，没有像 rails 这么好用的框架)

##### 10.2.2 用户只能编辑自己的资料

##### 10.2.3 友好的转向

用 session 存储原始请求

#### 10.3 列出所有用户

1. 使用 Faker 库 fake 100 个用户
1. 分页 (重要) `will_paginate` 库会给 ActiveRecord 类扩展 paginate 方法
1. 局部视图 `<%= render @users %>`

#### 10.4 删除用户 (只有管理员可以删除)

需要双重 check，首先，在网页上，只有管理员才能看到删除链接，但这不够，因为用户可以通过命令行或程序发送 api 来执行 删除。
因此，还需要在后台删除时确认执行者是管理员身份。

### 第 11 章 激活账户

简略读之。

将 `account_activation` 看作资源，但没有对应的 model。

    resources :account_activations, only: [:edit]

    GET /account_activation/<token>/edit edit edit_account_activation_url(token)

> 前面说过，我们要在激活邮件中发送一个独一无二的激活令牌。为此，可以在数据库中存储一个字符串,并将其放到激活地址中。可是，这样做有安全隐患，一旦被"脱裤"，将造成危害。例如，攻击者获得数据库的访问权可以立即激活新注册的账户(将以那个用户的身份登录)，然后修改密码，获得账户的控制权。

(恍然大悟! 存储令牌而不是原文，原因之一是为了防止脱库)

- `before_create`：在 User.new 之后马上调用
- `befreo_save`: 在 user.save 之前调用

#### 11.2 发送账户激活邮件

#### 11.3 激活账户

讲到了 Ruby 的元编程，就是一种反射嘛，和 js 中使用方法的字符串来调用方法差不多。原来如此。

    a = [1,2,3]
    a.length
    a.send(:length)
    a.send("length")

使用 元编程 修改原来的 authenticated 方法：

    def authenticated?(attribute, token)
      digest = send("#{attribute}_digest")
      return false if digest.nil?
      BCrypt::Password.new(digest).is_password?(token)
    end

(我觉得对于动态语言来说，测试真的是至关重要啊，对于静态语言作用小一些)

### 第 12 章 重设密码

略，与密码设置，激活账户原理差不多。

### 第 13 章 用户的微博

#### 13.1 Microposts 模型

使用 `belongs_to` 和 `has_many` 方法后

相较于下面的方法

    Micropost.create
    Micropost.create!
    Micropost.new

我们得到了下面几个方法:

    user.microposts.create
    user.microposts.create!
    user.microposts.build

后者才是创建微博的正确方式,即通过相关联的用户对象创建。

?? 默认作用域，是什么鬼。

    default_scope -> { order(created_at: :desc) }

"箭头"句法，这表示一种对象，叫 Proc(procedure) 或 lambda，即匿名函数(没有名字的函数)。`->` 接受一个代码块(4.3.2 节)，返回一个 Proc,然后在这个 Proc 上调用 call 方法执行其中的代码。

#### 13.2 显示微博

#### 13.3 微博相关操作

发布，修改，删除

使用 `redirect_to request.referrer` 可以重定向到之前的 url

#### 13.4 图像上传，略。

`form_for` 中指定了 `html: { multipart: true }` 参数。为了支持文件上传功能,必须指定这个参数。

### 第 14 章 关注用户

(关键一章)

关注他人和自己被他人关注，只需要一张关系表即可，Relationship 表。

- `follower_id`，`followed_id`
- 当查找某人的粉丝时，用 `select follower_id from relationships where followed_id = ?`
- 当查找某个关注的对象时，用 `select followed_id from relationships where follower_id = ?`

##### 14.2.2 关注和取消关注

将 relationships 作为 resource，那么关注则是 create 操作，取消关键则是 destroy 操作。

create 操作时，参数放在 body 里，只需要被关注者的 id 就行了，因为自身的信息，如果是在 web 上，那么放在 session 里了，如果是 api，那么已经放在 header 的 token 里了。

那么 destroy 呢，应该是不需要额外的参数，参数都在 url 里了，url 里有 relationships 的 id。`DELETE /relationships/(:id)` (书里的实现着实有点绕)

关注按钮的 ajax 实现。好处是节省一次请求。如果用 `redirect_to`，相当于重新发送一次请求，而使用 ajax 作为 response 后，就只有这次请求，没有第二次请求。

(请求还是通过 Form 的 Post 发起的，并没有变成 ajax 请求，只是把请求后的 response 由原来的 html 变成了可执行的 js 代码，由 js 控制内容的刷新) (?? Really)

#### 14.3 动态流

直接使用底层的 sql 子查询语句来提升性能。

DONE~!

这是第二遍看书并练习了，这次的理解程度已经达到 95% 了。
