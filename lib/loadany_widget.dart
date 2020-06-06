import 'package:flutter/material.dart';

///加载更多回调
typedef LoadMoreCallback = Future<void> Function();

///构建自定义状态返回
typedef LoadMoreBuilder = Widget Function(
    BuildContext context, LoadStatus status);

///加载状态
enum LoadStatus {
  normal, //正常状态
  error, //加载错误
  loading, //加载中
  completed, //加载完成
}

enum LoadDirection {
  up,
  down,
}

///加载更多 Widget
class LoadAny extends StatefulWidget {
  ///加载状态
  final LoadStatus statusDown;
  final LoadStatus statusUp;

  ///加载更多回调
  final LoadMoreCallback onLoadDown;
  final LoadMoreCallback onLoadUp;

  ///自定义加载更多 Widget
  final LoadMoreBuilder loadMoreBuilder;

  ///CustomScrollView
  final CustomScrollView child;

  ///到底部才触发加载更多
  final bool endLoadDown;
  final bool endLoadUp;

  ///加载更多底部触发距离
  final double bottomTriggerDistance;
  final double topTriggerDistance;

  ///底部 loadmore 高度
  final double footerHeight;

  ///Footer key
  final Key _keyLastItem = Key("__LAST_ITEM");
  final Key _keyFirstItem = Key("__FIRST_ITEM");

  LoadAny({
    @required this.statusDown,
    @required this.child,
    @required this.onLoadDown,
    @required this.statusUp,
    this.onLoadUp,
    this.endLoadDown = true,
    this.endLoadUp = true,
    this.bottomTriggerDistance = 200,
    this.topTriggerDistance = 200,
    this.footerHeight = 40,
    this.loadMoreBuilder,
  });

  @override
  State<StatefulWidget> createState() => _LoadAnyState();
}

class _LoadAnyState extends State<LoadAny> {
  @override
  Widget build(BuildContext context) {
    ///添加 Footer Sliver
    dynamic check =
    widget.child.slivers.elementAt(widget.child.slivers.length - 1);

    ///判断是否已存在 Footer
    if (check is SliverSafeArea && check.key == widget._keyLastItem) {
      widget.child.slivers.removeLast();
    }

    widget.child.slivers.insert(0, loadWidget(widget.statusUp, LoadDirection.up));
    widget.child.slivers.add(loadWidget(widget.statusDown, LoadDirection.down));

    return NotificationListener<ScrollNotification>(
      onNotification: _handleNotification,
      child: widget.child,
    );
  }

  Widget loadWidget(LoadStatus status, LoadDirection direction) {
    return SliverSafeArea(
      key: direction == LoadDirection.down?widget._keyLastItem: widget._keyFirstItem,
      top: false,
      left: false,
      right: false,
      sliver: SliverToBoxAdapter(
        child: _buildLoadDown(status),
      ),
    );
  }

  ///构建加载更多 Widget
  Widget _buildLoadDown(LoadStatus status) {
    ///检查返回自定义状态
    if (widget.loadMoreBuilder != null) {
      Widget loadMoreBuilder = widget.loadMoreBuilder(context, status);
      if (loadMoreBuilder != null) {
        return loadMoreBuilder;
      }
    }

    ///返回内置状态
    if (status == LoadStatus.loading) {
      return _buildLoading();
    } else if (status == LoadStatus.error) {
      return _buildLoadError();
    } else if (status == LoadStatus.completed) {
      return _buildLoadFinish();
    } else {
      return Container(height: widget.footerHeight);
    }
  }

  ///加载中状态
  Widget _buildLoading() {
    return Container(
      height: widget.footerHeight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          SizedBox(
            child: CircularProgressIndicator(),
            width: 20,
            height: 20,
          ),
          SizedBox(width: 10),
          Text(
            'Загрузка...',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  ///加载错误状态
  Widget _buildLoadError() {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        //点击重试加载更多
        if (widget.onLoadDown != null) {
          widget.onLoadDown();
        }
      },
      child: Container(
        height: widget.footerHeight,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.error,
              color: Colors.red,
              size: 20,
            ),
            SizedBox(width: 10),
            Text(
              'Ошибка загрузки',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  ///加载错误状态
  Widget _buildLoadFinish() {
    return Container(
      height: widget.footerHeight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          SizedBox(
            width: 10,
            child: Divider(
              color: Colors.grey,
            ),
          ),
          SizedBox(width: 6),
          Text(
            'На этом всё',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          SizedBox(width: 6),
          SizedBox(
            width: 10,
            child: Divider(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  ///计算加载更多
  bool _handleNotification(ScrollNotification notification) {
    //当前滚动距离
    double currentExtent = notification.metrics.pixels;
    //最大滚动距离
    double maxExtent = notification.metrics.maxScrollExtent;

    double minExtent = notification.metrics.minScrollExtent;

    //滚动更新过程中，并且设置非滚动到底部可以触发加载更多
    if ((notification is ScrollUpdateNotification) && (!widget.endLoadDown || !widget.endLoadUp)) {
      bool down = (maxExtent - currentExtent <= widget.bottomTriggerDistance);
      bool up = (currentExtent <= widget.topTriggerDistance);
      return _checkLoadMore(down, up);
    }

    //滚动到底部，并且设置滚动到底部才触发加载更多
    if ((notification is ScrollEndNotification) && widget.endLoadDown) {
      //滚动到底部并且加载状态为正常时，调用加载更多
      bool down = (currentExtent >= maxExtent);
      bool up = currentExtent <= minExtent;
      return _checkLoadMore(down, up);
    }

    return false;
  }

  ///处理加载更多
  bool _checkLoadMore(bool canLoadDown, bool canLoadUp) {
    if (canLoadDown && widget.statusDown == LoadStatus.normal) {
      if (widget.onLoadDown != null) {
        widget.onLoadDown();
        return true;
      }
    }
    else if (canLoadUp && widget.statusUp == LoadStatus.normal) {
      if (widget.onLoadUp != null) {
        widget.onLoadUp();
        return true;
      }
    }
    return false;
  }
}
