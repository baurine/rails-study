# Ruby on Rails Tutorial - Note 4

### 第 9 章 更新，显示和删除用户

这章完成用户资源的所有 REST 动作。包括 edit, update, index, destroy。

创建管理员。

#### 9.1 更新用户

##### 9.1.1 创建表单

在 UsersController 控制器中增加 edit 动作。内容和 new 动作一样。

    def edit
      @user = User.find(params[:id])
    end

在 views 目录下创建 edit.html.erb 页面，内容与 new.html.erb 基本相同。也是一个表单。

    <a href="http://gravatar.com/emails" target="_blank">change</a>

`target="_blank"` 表示在新窗口中打开链接。

查看表单 `form_for` 生成的 html 源代码，发现一段代码：

    <input type="hidden" name="_method" value="patch" />

因为浏览器不支持 patch 请求，所以 rails 用这样一种方法来曲线实现 patch 请求。

`form_for` 在生成表单的 html 代码时，怎么知道在新建时是发送 post 请求，而在编辑时是发送 patch 请求呢。通过 Active Record 提供的 `new_record?` 方法来知道是新建用户还是更新用户。

    $ rails console
    >> User.new.new_record?
    => true
    >> User.first.new_record?
    => false

##### 9.1.2 编辑表单失败的处理

和注册新用户时一样的处理。逻辑写在 UsersController 的 update 动作中。内容与 create 动作差不多。

    def update
      @user = User.find(params[:id])
      if @user.update_attributes(new_params)
        redirect_to @user
      else
        render 'edit'
      end
    end

##### 9.1.3 测试编辑表单失败

使用集成测试。

    test "unsuccessful edit" do
      get edit_user_path(@user)
      patch user_path(@user), user: {name: '',
                                     email: 'foobar@example.com',
                                     password: 'foo',
                                     password_confirmation: 'bar'}
      assert_template 'users/edit'
    end

##### 9.1.4 测试编辑表单成功（使用 TDD）

    test "successful edit" do
      get edit_user_path(@user)
      name = "Foo"
      email = "bar@example.com"
      patch user_path(@user), user: {name: name,
                                     email: email,
                                     password: '',
                                     password_confirmation: ''}
      assert_not flash.empty?
      assert_redirected_to @user
      @user.reload
      assert_equal @user.name, name
      assert_equal @user.email, email
    end

#### 9.2 权限系统

##### 9.2.1 必须先登录

使用事前过滤器。其实相当于一种回调，在登录前调用一个方法。插件思想。又类似于 Android 的 activity 的 `onCreate()` 方法。

    class UsersController < ApplicationController
      before_action :logged_in_user, only:[:edit, :update]

      ...
      private
        # 事前过滤器
        # 确保已登录
        def logged_in_user
          unless logged_in?
          flash[:danger] = "Please log in first!"
          redirect_to login_url
        end
    end

但是目前有漏洞，任意一个用户只要登录后就能编辑其它任何人的资料。因为它只判断了是否，而没有判断要修改的人是否是自己。

测试：在测试 edit user 时先用 `log_in_as(@user)` 进行登录

##### 9.2.2 用户只能编辑自己的资料

先写测试文件。在 fixtures 中新增一个测试用户。

    fixtures/users.yml
    michael:
      name: Michael
      email: michael@example.com
      password_digest: <%= User.digest("1234567") %>

    archer:
      name: Archer
      email: archer@example.com
      password_digest: <%= User.digest("1234567") %>

在 `users_controller_test.rb` 中增加测试代码：

    test "should redirect edit when edit different user" do
      log_in_as(@other_user)
      get :edit, id: @user
      assert_redirected_to root_url
    end

    test "should redirect update when update different user" do
      log_in_as(@other_user)
      patch :update, id: @user, user: {name:@user.name, email:@user.email}
      assert_redirected_to login_url
    end

在 `users_controller` 中增加事前过滤器：

    before_action :correct_user, only:[:edit, :update]
      ...

    # 事前过滤器，确保是当前用户
    def correct_user
      @user = User.find(params[:id])
      redirect_to(root_url) unless current_user?(@user)
    end

##### 9.2.3 实现友好的转向

方法是在转向之前把当前 url 保存起来，需要转向时再把之前保存到 url 取出来，并转向到此 url。保存在 session 中。注意写测试文件。

#### 9.3 列出所有用户

##### 9.3.1 用户列表

只允许登录用户查看。

    // index.html.erb
    <ul class="users">
      <% @users.each do |user| %>
        <li>
        <%= gravatar_for user, size:50 %>
        <%= link_to user.name, user %>
        </li>
      <% end %>
    </ul>

##### 9.3.2 示例用户

用 rails 产生大量模拟用户。用 faker gem 可以产生模拟的名字。

rails 使用 db/seeds.rb 来向数据库中添加示例用户

    User.create!(name:"Example",
                email: "example@railstutorial.org",
                password: "foobar",
                password_confirmation: "foobar")

    99.times do |n|
      name = Faker::Name.name
      email = "example-#{n}@railstutorial.org"
      password = "1234567"
      User.create!(name: name,
      email: email,
      password: password,
      password_confirmation: password)
    end

create! 方法和 create 类似，但出错时不是返回 false，而是抛出异常。

导入数据库

    $ bundle exec rake db:migrate:reset
    $ bundle exec rake db:seed

##### 9.3.3 分页

Rails 中实现分页的方法之一，`will_paginate`。

需要使用 `will_paginate` 和 `bootstrap-will_paginate` 两个 gem。

    // index.html.erb
    <%= will_paginate %>

    // users_controller.rb
    def index
      @users = User.paginate(page: params[:page])
    end

##### 9.3.4 列表页的测试

同样的，在 fixtures/users.yml 中模拟生成多个用户。然后为 `users_index` 编写集成测试代码。

在 fixture/user.yml 中增加以下代码后，导致测试有一个失败。不知为何? 待追查。

    <% 30.times do |n| %>
      user_<%= n %>:
        name: <%= "User #{n}" %>
        email: <%= "user-#{n}@example.com" %>
        password_digest: <%= User.digest('password') %>
    <% end %>

##### 9.3.5 使用局部视图重构

#### 9.4 删除用户

destroy 动作。首先创建管理员账户。

##### 9.4.1 管理员

为用户模型增加一个 admin 属性，类型为 boolean，从而会自动生成 admin? 方法。

    $ rails generate migration add_admin_to_users admin:boolean

修改迁移文件，增加默认值为 false 的选项。

    class AddAdminToUsers < ActiveRecord::Migration
      def change
        add_column :users, :admin, :boolean, default: false
      end
    end

修改 db/seeds.rb，把第一个用户设置为 admin。

重置数据库。

安全性问题：如果没有安全措施，用户通过工具发送 `patch /users/17?admin=true` 的请求，就可以把自己修改了管理员。我们前面的代码中，在接收用户的参数时，有一层过滤，只接收我们想要的参数，就可以把这个安全隐患排除。即

    def user_params
      params.require(:user).permit(:name, :email, :password, :password_confirmation)
    end

由于网站的特殊性，所有 url 是对外公开可见的，所以安全是头等大事。一定要把权限管理做得很好。

##### 9.4.2 destroy 动作

当登录用户为管理员时，可以看到用户列表中的删除按钮。(不能删除自己) 

为 destroy 增加事前过滤器，确保已登录且是管理员，以避免安全问题。

##### 9.4.3 删除的测试

先在 fixtures/usres.yml 中把第一个用户设为管理员。

然后在 `users_controller_test` 中测试 destroy 失败的情况。

然后在 `users_index_test` 中进行集成测试，测试页面元素，及 destroy 成功的情况。

可见，在控制器测试中只测试逻辑，而在集成测试中还进行页面元素的测试。

#### 9.5 小结

!!! 学到的最重要的，使用健壮参数和事前过滤器，提升网站的安全。

#### 9.6 练习

1. 测试 admin 属性不能被修改
1. 抽取 new 和 edit 页面中的重复布局

### 第 10 章 账户激活和密码重设

#### 10.1 账户激活

步骤：略。

##### 10.1.1 资源

1. 生成 AccountActivations 控制器
1. 为 edit 动作指定具名路由：`resources :account_activations, only: [:edit]`
1. 数据库迁移，增加 `activation_digest`, `activated`, `activated_at` 列
1. 为 `before_create` 指定回调函数：`create_activation_digest`。在创建新用户前生成 `activation_digest`
1. 为 User 模型增加 `activation_token` 虚拟属性。
1. 为种子用户(db/seeds.rb) 和 fixtures/users.yml 指定 `activated` 和 `activated_at` 属性值。

##### 10.1.2 邮件程序

!!! 教程已经过时了...

大致明白了。

1. 生成 mailer

        $ rails generate mailer UserMailer accout_activation password_reset

   与控制器类似，同时生成 `accout_activation` 和 `password_reset` 两个视图模版，有 text 和 html 两种格式。

1. 修改 UserMailer::account_activation 方法和相应的视图模版

        def account_activation(user)
          @user = user
          mail to: user.email, subject: "Account activation"
        end

   具名路由

        edit_account_activation_url(@user.activation_token, email: @user.email)

   生成的 url：

        account_activations/q5lt38hQDc_959PVoo6b7A/edit?email=foo%40example.com

   token 部分的内容通过 params[:id] 获得，参数部分通过 params[:email] 获得。

   !!! 所以这里有一个问题，参数部分不可以用 id 作为 key 值。

1. 设置开发环境邮件环境

        config/environments/development.rb
        config.action_mailer.raise_delivery_errors = true
        config.action_mailer.delivery_method = :test
        host = 'example.com'
        config.action_mailer.default_url_options = { host: host }

1. 修改邮件预览程序

        // test/mailers/previews/user_mailer_preview.rb
        def account_activation
          user = User.first
          user.activation_token = User.new_token
          UserMailer.account_activation(user)
        end

1. 测试，同时要修改 测试环境的邮件环境

   用 assert_match 进行文本匹配，支持正则。

        assert_match CGI::escape(user.email), mail.body.encoded

1. 注册过程中添加激活账号代码

        // app/controllers/users_controller.rb
        def create
          @user = User.new(new_params)
          if @user.save
            UserMailer.account_activation(@user).deliver_now
            flash[:info] = "Please check your email to activate your accout"
            redirect_to root_url
          else
            #puts 'save failed'
            render 'new'
          end
        end

##### 10.1.3 激活账户

1. 使用 ruby 元编程改写 User.authenticated 方法。使用 send 方法可以调用任意其它方法和属性。 (感觉像是和 js 的 apply 类似，其实到 c++ 层次就是函数指针啦)。

        a.length
        a.send(:length)
        a.send('length)

        def authenticated?(attribute, token)
          #puts "***************#{remember_digest}$$$$$$$$$$$$$$$$"
          digest = send("#{attribute}_digest")
          return false if digest.nil?
          BCrypt::Password.new(digest).is_password?(token)
        end

1. 编写 AccountActivationController 的 edit 动作。

   判断是否激活，未激活，则更新属性为激活，跳转到用户信息界面。否则提示错误，跳转到主页。

1. 禁止未激活的用户登录。

#### 10.1.4 测试和重构

1. 测试
1. 重构：把 activate 逻辑和发送邮件的逻辑从控制器中移到 User 模型中

#### 10.2 密码重设

步骤：略。

##### 10.2.1 资源

1. 生成 PasswordReset 控制器

        $ rails generate controller PasswordReset new edit --no-test-framework

1. 指定路由

        resources :password_reset only: [:new, :create, :edit, :update]

1. 在登录界面添加忘记密码的链接

        <%= link_to "(Forgot password)", new_password_reset_path %>

1. 添加数据迁移，添加 `reset_digest` 和 `reset_sent_at` 列

##### 10.2.2 控制器和表单

1. 修改 new.html.erb，实现填写邮件地址的表单
1. 实现 `password_reset` 的 create 动作
1. 在 user 模型中增加修改密码所需方法

##### 10.2.3 邮件程序

与激活账户差不多

1. 修改 user_mail 中 password_reset 方法
1. 修改邮件视图
1. 修改预览
1. 测试

##### 10.2.4 重设密码

1. 在 edit 视图中实现修改密码的表单，同时把用户的邮件地址隐藏中表单中提交。使用 `<%= hidden_field_tag ... %>`
1. 事前过滤器：`get_user`, `valid_user`, `check_reset_expiration`
1. 实现 update 动作

##### 10.2.5 测试

略。

剩余部分见 [Note 5](./note-5.md)。
