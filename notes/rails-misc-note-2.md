# Rails Misc Note 2

1. routes 中的 resource 与 resources 的区别

## routes 中的 resource 与 resources 的区别

以一个博客网站为例，一个用户可以给一篇文章创建多个评论，即 routes 应该是这样的：

    resources :posts do
      resources :comments
    end

这样，在用户登录的情况下，创建一个新的评论的 API 是 `POST /posts/:post_id/comments`，删除一个 comment 的 API 是 `DELETE /posts/:post_id/comments/:id`，我们也通过下面的路由来快速地删除一个 comment：

    resources :comments, except: :create

这样，删除一个 comment 也可以用 API: `DELETE /comments/:id`。

和 comment 允许多个不一样的是，如果允许用户对一篇文章进行 favorite/like/star，无论操作多少次，都只会生成一个 favorite/like/star。假如我们对一篇文章进行 like，可以用 API `POST /posts/:post_id/likes`，但是删除的时候，我们更希望用 `DELETE /posts/:post_id/likes`，而不是 `DELETE /posts/:post_id/likes/:id` 或 `DELETE /likes/:id`，因为每个用户对一篇文章只有一个 like，那么此时，我们就要在 routes 中使用 resource，而不是 resources 了：

    resources :posts do
      resources :comments
      resource  :likes
    end

`resources :likes` 将会生成 `DELETE /posts/:post_id/likes/:id` 的 API，而 `resource :likes` 生成 `DELETE /posts/:post_id/likes` 的 API。

至于 resource 后面应该用 `like` 还是 `likes`，其实也不好定夺，因为对某篇 post 来说，它是可以有多个 likes 的呀，但对于一个用户来说，它对某篇 post 只能有一个 like，所以我持保留意见，`like` 或 `likes` 都可以。

如果是 `resouce :like`，那么生成的 API 是这样的：`POST /posts/:post_id/like`, `DELETE /posts/:post_id/like`。

阅读了 [GitHub 关于此类 API 的设计](https://developer.github.com/v3/activity/starring/#star-a-repository) 后，我觉得上面这个 API 更好的设计是这样的：

    # 获取自己或某人是否 like 了某篇文章
    GET /user/liked/posts/:post_id
    GET /users/:user_id/liked/posts/:post_id

    # like 一篇文章，操作是幂等的
    PUT /user/liked/posts/:post_id

    # un-like 一篇文章
    DELETE /user/liked/posts/:post_id

相比上面的设计更合理的地方在于，like post 应该是幂等操作，而一般来说 PUT 是幂等的，而 POST 不是。在 API url 中同时体现了主语和宾语，也更合理。

那这样的 API routes 应该怎么写呢？

    resource :user do
      resource :liked, only: [] do
        resources :posts, only: [:index, :show, :update, :destroy], controller: :liked, param: :post_id
      end
    end

得到的路由是这样的：

    user_liked_posts GET    /user/liked/posts(.:format)                         liked#index
     user_liked_post GET    /user/liked/posts/:post_id(.:format)                liked#show
                     PATCH  /user/liked/posts/:post_id(.:format)                liked#update
                     PUT    /user/liked/posts/:post_id(.:format)                liked#update
                     DELETE /user/liked/posts/:post_id(.:format)                liked#destroy

注意，如果你不加上 `controller: :liked, param: :post_id`，那么得到的默认路由是这样的：

    user_liked_posts GET    /user/liked/posts(.:format)                         posts#index
     user_liked_post GET    /user/liked/posts/:id(.:format)                     posts#show
                     PATCH  /user/liked/posts/:id(.:format)                     posts#update
                     PUT    /user/liked/posts/:id(.:format)                     posts#update
                     DELETE /user/liked/posts/:id(.:format)                     posts#destroy
