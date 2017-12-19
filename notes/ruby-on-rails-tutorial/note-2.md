# Ruby on Rails Tutorial - Note 2

### 第 5 章 完善布局

主要是 html 和 css。

要在页面中加上 LOGO，导航条和网站底部。

#### 5.1

##### 5.1.1 网站导航

增加了 header, nav 等元素，及 ie9 的兼容解决方案。

    <body>
      <header class="navbar navbar-fixed-top navbar-inverse">
        <div class="container">
          <%= link_to "sample app", '#', id: "logo" %>
          <nav>
            <ul class="nav navbar-nav pull-right">
              <li><%= link_to "Home", '#' %></li>
              <li><%= link_to "Help", '#' %></li>
              <li><%= link_to "Log in", '#' %></li>
            </ul>
          </nav>
        </div>
      </header>

      <div class="container">
        <%= yield %>
      </div>
    </body>

header, nav, section 是 html 中新增的标签 (元素)。

container, navbar, navbar-fixed-top, navbar-inverse 是在 bootstrap 中定义的 css 类，稍候会引入 bootstrap 框架。

更新 home.html.erb。

    <div class="center jumbotron">
      <h1>
        Welcome to the Sample App
      </h1>
      <h2>
        This is the home page for the
        <a href="http://www.railstutorial.org/">
          Ruby on Rails Tutorial
        </a>
        sample application.
      </h2>
      <%= link_to "Sign up now!", '#', class: "btn btn-lg btn-primary" %>
    </div>
    <%= link_to image_tag("rails.png", alt: "Rails logo"), 'http://rubyonrails.org/' %>

在 cloud9 上用 `curl -O http://rubyonrails.org/images/rails.png` 下载图片时，只能下载到 app/asset/images 目录，在根目录下没有下载权限。

`image_tag` 生成的 html 代码：

    <img alt="Rails logo" src="/assets/rails-9308b8f92fea4c19a3a0d8385b494526.png" />

##### 5.1.2 Bootstrap 和 自定义的 css

安装 bootstrap，在 rails 中可以使用 bootstrap-sass 这个 gem。bootstrap 是用 LESS 编写动态样式表，而 rails 的 Assert Pipeline 默认是支持 SASS 的。bootstrap-sass 可以把 bootstrap 由 less 转成 sass。

把 `gem 'bootstrap-sass', '3.2.0.0'` 加到 Gemfile 中。然后 bundle install。

    $ touch app/assets/stylesheets/custom.css.scss

在这个 css 中引入 bootstrap 的内容

    @import "bootstrap-sprockets";
    @import "bootstrap";

自己定义了一些 css style。略。

##### 5.1.3 使用局部视图

    <head>
      <title><%= full_title(yield(:title)) %></title>
      <%= csrf_meta_tags %>
      <%= stylesheet_link_tag    'application', media: 'all',
                                                'data-turbolinks-track': 'reload' %>
      <%= javascript_include_tag 'application', 'data-turbolinks-track': 'reload' %>
      <%= render 'layouts/shim' %>
    </head>
    <body>
      <%= render 'layouts/header' %>
      <div class="container">
        <%= yield %>
      </div>
    </body>

layouts/shim 对应 layouts/_shim.html.erb。

增加 layouts/_footer.html.erb 局部视图

    <footer class="footer">
      <small>
        The <a href="http://www.railstutorial.org/">Ruby on Rails Tutorial</a>
        by <a href="http://www.michaelhartl.com/">Michael Hartl</a>
      </small>
      <nav>
        <ul>
          <li><%= link_to "About", '#' %></li>
          <li><%= link_to "Contact", '#' %></li>
          <li><a href="http://news.railstutorial.org/">News</a></li>
        </ul>
      </nav>
    </footer>

(我发现，内部链接使用了 `link_to` 方法，外部链接直接用 `<a>` 标签)

#### 5.2 Sass 和 Asset Pipeline

Asset Pipeline 用来合并 css, js 到一个文件中，并进行压缩。

资源文件：
- app/assets, lib/assets, vendor/assets
- assets/images, assets/javascripts, assets/stylesheets

rails 使用 Sprockets gem 来合并 js 和 css。

css 的合并规则写在 assets/stylesheets/application.css 中。

    *= require_tree .
    *= require_self

预处理引擎，根据后缀名决定。

- .scss --> Sass
- .coffee --> CoffeeScript
- .erb --> Ruby

##### 5.2.2 句法强大的样式表 (Sass)

最主要的两个功能：嵌套和变量

嵌套：

    footer {
      margin-top: 45px;
      padding-top: 5px;
      border-top: 1px solid #eaeaea;
      color: #777;
      a {
        color: #555;
        &: hover {
          color: #222;
      }
    }

变量：

    $light-gray: #777;

    h2 {
      ...
      color: $light-gray;
    }

bootstrap 原生使用 less 语法，定义变量语法是用 @ 打头，如 @light-gray:#777。

#### 5.3 布局中的链接

使用具名路由

    <%= link_to "About", about_path %>

##### 5.3.2 Rails 路由

    root 'static_pages#home'

会生成两个具名路由：

    root_path '/'
    root_url 'http://www.example.com/'

一般情况下，使用 `_path` 格式即可，重定向情况下使用 `_url` 格式。

    get 'help' => 'static_pages#help'

对应的两个具名路由：

    help_path '/help'
    help_url 'http://www.example.com/help'

##### 5.3.4 集成测试，测试链接

前面学习的测试只是测试单个控制器。

    $ rails generate integration_test site_layout

    class SiteLayoutTest < ActionDispatch::IntegrationTest
      test "layout links" do
        get root_path
        assert_template 'static_pages/home'
        assert_select "a[href=?]", root_path, count: 2
        assert_select "a[href=?]", help_path
        assert_select "a[href=?]", about_path
        assert_select "a[href=?]", contact_path
      end
    end

`assert_template`，`assert_select` 的使用。

    $ bundle exec rake test:integration
    $ bundle exec rake test

#### 5.4 用户注册

创建用户控制器及 new 动作。

    $ rails generate controller Users new

修改 views/users/new.html.erb

    <h1>SignUp</h>
    <p>...</p>

修改路由

    get 'signup' ==> 'users#new'

修改 home.html.erb

    <%= link_to 'Sign Up Now!', signup_path, class:'btn btn-lg ...'>

修改测试文件，略。

### 第 6 章 用户模型

创建网站的用户数据模型，存储数据。

6-10 章实现整个注册，登录功能。6-8 章实现注册功能。

#### 6.1 用户模型

Active Record。其实是一种 ORM。

##### 6.1.1 数据库迁移 (migration)

创建控制器用 generate controller 命令

    $ rails generate controller Users new

创建用户模型用 generate model 命令

    $ rails generate model User name:string email:string

(!!! 注意，控制器用复数，但模型用单数。如上所示，控制器是 Users，模型是 User，但生成的表名仍是复数，即 users。因为模型是定义单条记录的格式，而表是存储多条记录。)

执行 generate model 命令后自动生成迁移文件，迁移文件的作用是创建或修改相应的数据库表结构。

    // db/migrate/[timestamp]_create_users.rb
    class CreateUsers < ActiveRecord::Migration[5.0]
      def change
        create_table :users do |t|
          t.string :name
          t.string :email

          t.timestamps
        end
      end
    end

自动生成 id, `create_at`, `update_at` 列。

使用 rake db:migration 命令来执行这个迁移

    $ bundle exec rake db:migration

撤消操作

    $ bundle exec rake db:rollback

##### 6.1.2 模型文件

    // app/models/user.rb
    class User < ActiveRecord::Base
    end

##### 6.1.3 创建用户对象

    $ rails console --sandbox
    >> User.new
    >> user = User.new(name:'baurine', email:'bao@example.com')
    >> user.valid?
    >> user.save
    >> user
    >> foo = User.create(name:'foo', email:'foo@example.com') // = new + save
    >> foo.name
    >> foo.email
    >> foo.destroy

##### 6.1.4 查找对象

    >> User.find(1)
    >> User.find_by(email: "mhartl@example.com")
    >> User.first
    >> User.all

##### 6.1.5 更新对象

    >> user.email = "mhartl@example.net"
    >> user.save
    >> user.reload.email
    >> user.update_attributes(name: "The Dude", email: "dude@abides.org")
    >> user.update_attribute(:name, "The Dude")

#### 6.2 用户数据验证

常用的数据验证：存在性、长度、格式、唯一性。

TDD 并不适合所有情况，但是模型验证是使用 TDD 的绝佳时机。

##### 6.2.1 有效性测试

    assert @user.valid?

    $ bundle exec rake test:models

##### 6.2.2 存在性验证

    test "name should be present" do
      @user.name = " "
      assert_not @user.valid?
    end

    // app/models/user.rb
    class User < ActiveRecord::Base
      validates :name, presence: true
    end

    >> user.errors.full_messages //查看错误信息
    => ["Name can't be blank"]

##### 6.2.3 长度验证

    test "name should not be too long" do
      @user.name = "a" * 51
      assert_not @user.valid?
    end

    test "email should not be too long" do
      @user.email = "a" * 256
      assert_not @user.valid?
    end

    class User < ActiveRecord::Base
      validates :name, presence: true, length: { maximum: 50 }
      validates :email, presence: true, length: { maximum: 255 }
    end

##### 6.2.4 格式验证

email 的格式验证，使用正则。

    test "email validation should reject invalid addresses" do
      invalid_addresses = %w[user@example,com user_at_foo.org user.name@example.
      foo@bar_baz.com foo@bar+baz.com]

      invalid_addresses.each do |invalid_address|
        @user.email = invalid_address
        assert_not @user.valid?, "#{invalid_address.inspect} should be invalid"
      end
    end

    class User < ActiveRecord::Base
      validates :name, presence: true, length: { maximum: 50 }
      VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
      validates :email, presence: true, length: { maximum: 255 },
      format: { with: VALID_EMAIL_REGEX }
    end

##### 6.2.5 唯一性验证

要做两层唯一性验证，一层是在内存中生成 user 对象时，一层是把对象存入数据库时。

生成 user 对象时（注意 email 要忽略大小写）：

    test "email should be unique" do
      duplicate_user = @user.dup
      @user.save
      duplicate_user.email = @user.email.upcase
      assert_not duplicate_user.valid?
    end

    class User < ActiveRecord::Base
      validates :name, presence: true, length: { maximum: 50 }
      VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
      validates :email, presence: true, length: { maximum: 255 },
      format: { with: VALID_EMAIL_REGEX }, uniqueness: { case_sensitive: false }
    end

写入数据库时：

为 email 建立索引，并指定其值是 unique。存入之前一律变成小写。

    $ rails generate migration add_index_to_users_email

    class AddIndexToUsersEmail < ActiveRecord::Migration
      def change
        add_index :users, :email, unique: true # add_index 方法是 rails 内置方法，添加索引
      end
    end

    $ bundle exec rake db:migrate

email 存入数据库前变成小写，使用 `before_save` 回调。

    class User < ActiveRecord::Base
      before_save { self.email = self.email.downcase }
      validates :name, presence: true, length: { maximum: 50 }
      VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
      validates :email, presence: true, length: { maximum: 255 },
      format: { with: VALID_EMAIL_REGEX }, uniqueness: { case_sensitive: false }
    end

#### 6.3 添加安全密码

##### 6.3.1 计算密码哈希值

使用 Rails 方法， `has_secure_password`。加到 User 模型中。

    class User < ActiveRecord::Base
      ...
      has_secure_password
    end

`has_sercure_password` 要求模型中有 `password_digest` 这一列。

创建迁移文件

    $ rails generate migration add_password_digest_to_users password_digest:string

    db/migrate/[timestamp]_add_password_digest_to_users.rb
      class AddPasswordDigestToUsers < ActiveRecord::Migration
      def change
        add_column :users, :password_digest, :string
      end
    end

`has_secure_password` 使模型获得 password 和 `password_confirmation` 两个虚拟属性，即这两个属性只在内存对象中，而不存在数据库中。

`has_secure_password` 需要安装 bcrypt 这个 gem。

`has_secure_password` 还使模型获得 authenticate 方法。

##### 6.3.3 增加密码长度验证

测试文件：

    test "password should have a minimum length" do
      @user.password = @user.password_confirmation = "a" * 5
      assert_not @user.valid?
    end

在模型 User 中增加：

    validates :password, lenght: {minimum:6}

##### 6.3.4 创建并认证用户

    ...
    a_user.authenticate('foobar')

`authenticate()` 这个方法，如果验证密码成功，返回的是 `a_user` 这个对象，如果失败，返回的是布尔值 false。所以要用 `!!` 还把结果全部统一成布尔值。

    >> !!a_user.authenticate('foobar')
    => true