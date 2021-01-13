import AppKit
import Foundation
import Cocoa

final class PixelImageView: NSImageView {
  override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)

    imageScaling = .scaleProportionallyUpOrDown

    wantsLayer = true
    layer?.shouldRasterize = true
    layer?.magnificationFilter = .nearest
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

final class LCDViewController: NSViewController {
  let screenImageView = PixelImageView()

  override func loadView() {
    view = NSView()

    screenImageView.frame = view.bounds
    screenImageView.autoresizingMask = [.width, .height]
    view.addSubview(screenImageView)
  }

  override func viewWillAppear() {
    super.viewWillAppear()

    guard let document = projectDocument else {
      fatalError()
    }
    document.emulationObservers.append(self)
    screenImageView.image = document.gameboy.takeScreenshot()
  }
}

extension LCDViewController: EmulationObservers {
  func emulationDidAdvance(screenImage: NSImage, tileDataImage: NSImage, fps: Double?, ips: Double?) {
    screenImageView.image = screenImage
  }

  func emulationDidStart() {}
  func emulationDidStop() {}
}
