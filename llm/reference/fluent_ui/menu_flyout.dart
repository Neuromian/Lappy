FlyoutTarget(
  controller: controller,
  child: Button(
    child: const Text('Clear cart'),
    onPressed: () {
      controller.showFlyout(
        autoModeConfiguration: FlyoutAutoConfiguration(
          preferredMode: FlyoutPlacementMode.topCenter,
        ),
        barrierDismissible: true,
        dismissOnPointerMoveAway: false,
        dismissWithEsc: true,
        navigatorKey: rootNavigatorKey.currentState,
        builder: (context) {
          return FlyoutContent(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'All items will be removed. Do you want to continue?',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12.0),
                Button(
                  onPressed: Flyout.of(context).close,
                  child: const Text('Yes, empty my cart'),
                ),
              ],
            ),
          );
        },
      );
    },
  )
)


final menuController = FlyoutController();

FlyoutTarget(
  controller: menuController,
  child: Button(
    child: const Text('Options'),
    onPressed: () {
      menuController.showFlyout(
        autoModeConfiguration: FlyoutAutoConfiguration(
          preferredMode: FlyoutPlacementMode.topCenter,
        ),
        barrierDismissible: true,
        dismissOnPointerMoveAway: false,
        dismissWithEsc: true,
        navigatorKey: rootNavigatorKey.currentState,
        builder: (context) {
          return MenuFlyout(items: [
            MenuFlyoutItem(
              leading: const Icon(FluentIcons.share),
              text: const Text('Share'),
              onPressed: Flyout.of(context).close,
            ),
            MenuFlyoutItem(
              leading: const Icon(FluentIcons.copy),
              text: const Text('Copy'),
              onPressed: Flyout.of(context).close,
            ),
            MenuFlyoutItem(
              leading: const Icon(FluentIcons.delete),
              text: const Text('Delete'),
              onPressed: Flyout.of(context).close,
            ),
            const MenuFlyoutSeparator(),
            MenuFlyoutItem(
              text: const Text('Rename'),
              onPressed: Flyout.of(context).close,
            ),
            MenuFlyoutItem(
              text: const Text('Select'),
              onPressed: Flyout.of(context).close,
            ),
            const MenuFlyoutSeparator(),
            MenuFlyoutSubItem(
              text: const Text('Send to'),
              items: (_) => [
                MenuFlyoutItem(
                  text: const Text('Bluetooth'),
                  onPressed: Flyout.of(context).close,
                ),
                MenuFlyoutItem(
                  text: const Text('Desktop (shortcut)'),
                  onPressed: Flyout.of(context).close,
                ),
                MenuFlyoutSubItem(
                  text: const Text('Compressed file'),
                  items: (context) => [
                    MenuFlyoutItem(
                      text: const Text('Compress and email'),
                      onPressed: Flyout.of(context).close,
                    ),
                    MenuFlyoutItem(
                      text: const Text('Compress to .7z'),
                      onPressed: Flyout.of(context).close,
                    ),
                    MenuFlyoutItem(
                      text: const Text('Compress to .zip'),
                      onPressed: Flyout.of(context).close,
                    ),
                  ],
                ),
              ],
            ),
          ]);
        },
      );
    },
  )
)