---
title: Vue异步组件详解
author: 丁文超 
date: 2019-09-10 19:11:14
categories: web
tags:
 - vue
 - web
 - async
 - component
---

# 定义

  在大型应用中，我们可能需要将应用分割成小一些的代码块，并且只在需要的时候才从服务器加载一个模块。为了简化，Vue 允许你以一个工厂函数的方式定义你的组件，这个工厂函数会异步解析你的组件定义。Vue 只有在这个组件需要被渲染的时候才会触发该工厂函数，且会把结果缓存起来供未来重渲染。

  异步组件的一个典型应用就是在配合`webpack`代码拆分时定义的`Vue`路由组件。

  ~~~js
   {
      name: 'meetingList',
      path: 'list',
      component: () => import('@/views/meeting/list.vue')
    }
  ~~~

上面代码`component`就被定义为函数返回一个`promise`，实质上就是一个异步组件。

# 异步组件的解析

我们定义一个`AsyncComponent`的异步组件, 这个组件只有被访问到时才会加载

~~html
<div>
    <AsyncComponent />
</div>
~~

~~js
  components: {
    AsyncComponent: () => import('./components/test-async-component/index.vue'),
  }
~~

以上组件在`rednder`时组件时会调用`createElement`创建`vnode，`对于组件`createElement`又会调用`createComponent`在`createComponent`内初始异步组件的代码如下。

~~js

export function createComponent (
  Ctor: Class<Component> | Function | Object | void,
  data: ?VNodeData,
  context: Component,
  children: ?Array<VNode>,
  tag?: string
): VNode | Array<VNode> | void {
  if (isUndef(Ctor)) {
    return
  }
  // Vue
  const baseCtor = context.$options._base

  // plain options object: turn it into a constructor
  // 对于异步组件传过来的是函数，所以不会执行Vue.extend
  if (isObject(Ctor)) {
    // 调用Vue.extend
    Ctor = baseCtor.extend(Ctor)
  }

  // async component
  // 异步组件
  let asyncFactory
  // 异步组件没经过 Vue.extend所以不存在Ctor.cid
  if (isUndef(Ctor.cid)) {
    asyncFactory = Ctor
    Ctor = resolveAsyncComponent(asyncFactory, baseCtor)
    if (Ctor === undefined) {
      // 异步组件未加载完毕，且没有loading组件创建占位节点
      // return a placeholder node for async component, which is rendered
      // as a comment node but preserves all the raw information for the node.
      // the information will be used for async server-rendering and hydration.
      return createAsyncPlaceholder(
        asyncFactory,
        data,
        context,
        children,
        tag
      )
    }
  }


  return vnode
}

~~

因为此时传入`Ctor`是函数所以没有调用`Vue.extend`所以`Ctor`上不存在`cid`属性，所以会调用`resolveAsyncComponent`解析异步组件。

~~js
export function resolveAsyncComponent (
  factory: Function,
  baseCtor: Class<Component>
): Class<Component> | void {
  if (isTrue(factory.error) && isDef(factory.errorComp)) {
      // 如果当前出错，返回错误组件
    return factory.errorComp
  }

  if (isDef(factory.resolved)) {
    // 如果已经被缓存了直接返回
    return factory.resolved
  }
  // 当前渲染Vue实例
  const owner = currentRenderingInstance
  if (owner && isDef(factory.owners) && factory.owners.indexOf(owner) === -1) {
    // already pending
    factory.owners.push(owner)
  }

  if (isTrue(factory.loading) && isDef(factory.loadingComp)) {
      // 返回loadding组件
    return factory.loadingComp
  }

  if (owner && !isDef(factory.owners)) {
    const owners = factory.owners = [owner]
    let sync = true
    let timerLoading = null
    let timerTimeout = null

    ;(owner: any).$on('hook:destroyed', () => remove(owners, owner))
    // 在组件发生变化时触发强制更新
    const forceRender = (renderCompleted: boolean) => {
      for (let i = 0, l = owners.length; i < l; i++) {
        (owners[i]: any).$forceUpdate()
      }

      if (renderCompleted) {
        owners.length = 0
        // 清除loading的计时器
        if (timerLoading !== null) {
          clearTimeout(timerLoading)
          timerLoading = null
        }
        // 清除timeout计时器
        if (timerTimeout !== null) {
          clearTimeout(timerTimeout)
          timerTimeout = null
        }
      }
    }
    // once确保传入的函数只执行一次，因为第一次执行后会缓存执行结果，所以函数只需要执行一次
    const resolve = once((res: Object | Class<Component>) => {
      // cache resolved
      factory.resolved = ensureCtor(res, baseCtor)
      // invoke callbacks only if this is not a synchronous resolve
      // (async resolves are shimmed as synchronous during SSR)
      if (!sync) {
        // 组件发生变化触发强制更新
        forceRender(true)
      } else {
        owners.length = 0
      }
    })
    // reject函数出错时调用
    const reject = once(reason => {
      process.env.NODE_ENV !== 'production' && warn(
        `Failed to resolve async component: ${String(factory)}` +
        (reason ? `\nReason: ${reason}` : '')
      )
      if (isDef(factory.errorComp)) {
        factory.error = true
        // 发生错误需要显示错误组件，强制更新
        forceRender(true)
      }
    })
    // 执行异步组件函数
    // 对于普通的函数异步组件，在这一步就会返回结果
    const res = factory(resolve, reject)
    // 如果返回的是Promise
    if (isObject(res)) {
      if (isPromise(res)) {
        // () => Promise
        if (isUndef(factory.resolved)) {
          // 在promise的成功回调内传入resolve， 和reject
          res.then(resolve, reject)
        }
      } else if (isPromise(res.component)) {
        // 高级的异步组件范湖一个对象，对象包含属性
        res.component.then(resolve, reject)

        if (isDef(res.error)) {
          // 缓存错误组件
          factory.errorComp = ensureCtor(res.error, baseCtor)
        }

        if (isDef(res.loading)) {
          // 缓存loading组件
          factory.loadingComp = ensureCtor(res.loading, baseCtor)
          if (res.delay === 0) {
             // 设置延迟0秒
            factory.loading = true
          } else {
             // 默认延迟200秒
            timerLoading = setTimeout(() => {
              timerLoading = null
              if (isUndef(factory.resolved) && isUndef(factory.error)) {
                factory.loading = true
                forceRender(false)
              }
            }, res.delay || 200)
          }
        }

        if (isDef(res.timeout)) {
          // 如果设置了超时时间，超时报错
          timerTimeout = setTimeout(() => {
            timerTimeout = null
            if (isUndef(factory.resolved)) {
              reject(
                process.env.NODE_ENV !== 'production'
                  ? `timeout (${res.timeout}ms)`
                  : null
              )
            }
          }, res.timeout)
        }
      }
    }

    sync = false
    // return in case resolved synchronously
    // 最后判断如果当前正在loading返回loading组件
    // 否则返回异步加载成功的组件
    return factory.loading
      ? factory.loadingComp
      : factory.resolved
  }
}
function ensureCtor (comp: any, base) {
  if (
    comp.__esModule ||
    (hasSymbol && comp[Symbol.toStringTag] === 'Module')
  ) {
    comp = comp.default
  }
  return isObject(comp)
    // 调用extend生成构造函数
    ? base.extend(comp)
    : comp
}
~~

以上代码总共有三种情况，分别代表着异步组件的三种写法。

# 工厂函数异步组件

对于普通函数异步组件会直接在`resolve`函数中缓存异步组件。

~~js
// 工厂函数异组件
Vue.component('async-example', function (resolve, reject) {
  setTimeout(function () {
    // 向 `resolve` 回调传递组件定义
    resolve({
      template: '<div>I am async!</div>'
    })
  }, 1000)
// 传入的resolve函数
const resolve = once((res: Object | Class<Component>) => {
    // cache resolved
    factory.resolved = ensureCtor(res, baseCtor)
    // invoke callbacks only if this is not a synchronous resolve
    // (async resolves are shimmed as synchronous during SSR)
    if (!sync) {
    // 组件发生变化触发强制更新
    forceRender(true)
    } else {
    owners.length = 0
    }
})
~~

# Promsie组件

除了工厂函数异步组件也是返回一个Promise

~~js
// 异步组件返回一个Promise
Vue.component(
  'async-webpack-example',
  // 这个 `import` 函数会返回一个 `Promise` 对象。
  () => import('./my-async-component')
)

const res = factory(resolve, reject)
    // 如果返回的是Promise
if (isObject(res)) {
    if (isPromise(res)) {
        // () => Promise
        if (isUndef(factory.resolved)) {
        // 在promise的成功回调内传入resolve， 和reject
        res.then(resolve, reject)
        }
    }
}

~~

首先判断返回的是不是对象之后判断是否是`Promise`如果是`Promise`则传入`resolve`和`reject`解析异步组件，这里的`resolve`和`reject`就是前文定义的。


# 高级异步组件

除此之外异步组件也可以返回一个对象包含下列选项

* `component` 异步组件
* `loading` 异步组件加载过程中的`loading`组件
* `error`    加载失败时使用的组件
*  `delay` 展示加载时组件的延时时间。默认值是 200 (毫秒)
* `timeout`  如果提供了超时时间且组件加载也超时了，则使用加载失败时使用的组件。默认值是：`Infinity`

~~js
// 异步组件返回一个对象
const AsyncComponent = () => ({
  // 需要加载的组件 (应该是一个 `Promise` 对象)
  component: import('./MyComponent.vue'),
  // 异步组件加载时使用的组件
  loading: LoadingComponent,
  // 加载失败时使用的组件
  error: ErrorComponent,
  // 展示加载时组件的延时时间。默认值是 200 (毫秒)
  delay: 200,
  // 如果提供了超时时间且组件加载也超时了，
  // 则使用加载失败时使用的组件。默认值是：`Infinity`
  timeout: 3000
})
// 解析高级异步组件

  if (isObject(res)) {
      if (isPromise(res)) {
        // () => Promise
        if (isUndef(factory.resolved)) {
          // 在promise的成功回调内传入resolve， 和reject
          res.then(resolve, reject)
        }
      } else if (isPromise(res.component)) {
        // 这个分支处理高级异步组件
        // 高级的异步组件范湖一个对象，对象包含属性
        res.component.then(resolve, reject)

        if (isDef(res.error)) {
          // 缓存错误组件
          factory.errorComp = ensureCtor(res.error, baseCtor)
        }

        if (isDef(res.loading)) {
          // 缓存loading组件
          factory.loadingComp = ensureCtor(res.loading, baseCtor)
          if (res.delay === 0) {
             // 设置延迟0秒, 立即显示loading组件
            factory.loading = true
          } else {
             // 默认延迟200秒
            timerLoading = setTimeout(() => {
              timerLoading = null
              if (isUndef(factory.resolved) && isUndef(factory.error)) {
                factory.loading = true
                forceRender(false)
              }
            }, res.delay || 200)
          }
        }

        if (isDef(res.timeout)) {
          // 如果设置了超时时间，超时报错
          timerTimeout = setTimeout(() => {
            timerTimeout = null
            if (isUndef(factory.resolved)) {
              reject(
                process.env.NODE_ENV !== 'production'
                  ? `timeout (${res.timeout}ms)`
                  : null
              )
            }
          }, res.timeout)
        }
      }
    }
~~

由上面我们可以看到一个异步组件有下面几种状态

* `loading` 当前组件正在加载。
* `error` 组件加载失败，如果有设置超时时间超时未加载成功也会把状态置为`error`。
* `done` 组件加载完成。

注意每次状态改变都会调用`forceRender`触发强制更新，因为状态改变显示的组件就会有变化。

~~js
    // 在组件发生变化时触发强制更新
    // 就是遍历调用实例的$forceUpdate
    const forceRender = (renderCompleted: boolean) => {
      for (let i = 0, l = owners.length; i < l; i++) {
        (owners[i]: any).$forceUpdate()
      }

      if (renderCompleted) {
        owners.length = 0
        // 清除计时器
        if (timerLoading !== null) {
          clearTimeout(timerLoading)
          timerLoading = null
        }
        if (timerTimeout !== null) {
          clearTimeout(timerTimeout)
          timerTimeout = null
        }
      }
    }
 
~~

这里再次回到`createComponet`, 当组件还未加载完成，或者设置了`delay`，则此时`resolveAsyncComponent`返回了`undefined`,此时调用`createAsyncPlaceholder`创建一个占位的`vnode`.

~~js
 if (isUndef(Ctor.cid)) {
    asyncFactory = Ctor
    Ctor = resolveAsyncComponent(asyncFactory, baseCtor)
    if (Ctor === undefined) {
      // 异步组件未加载完毕，且没有loading组件创建占位节点
      // return a placeholder node for async component, which is rendered
      // as a comment node but preserves all the raw information for the node.
      // the information will be used for async server-rendering and hydration.
      return createAsyncPlaceholder(
        asyncFactory,
        data,
        context,
        children,
        tag
      )
    }
  }
~~

~~js
export function createAsyncPlaceholder (
  factory: Function,
  data: ?VNodeData,
  context: Component,
  children: ?Array<VNode>,
  tag: ?string
): VNode {
  const node = createEmptyVNode()
  node.asyncFactory = factory
  node.asyncMeta = { data, context, children, tag }
  return node
}
~~

在`createAsyncPlaceholder`先创建一个空节点，之后将一系列上下文信息缓存在`node.asyncMeta`中。

由以上分析看到`Vue`解析异步组件的过程已经很清楚了, 需要注意的是异步组件每次状态改变都会触发强制更新，因为状态变了组件就变了，通过强制更新执行组件更新。


![异步组件流程.jpg](https://i.loli.net/2019/09/10/rDnhVolvOusk83t.png)
