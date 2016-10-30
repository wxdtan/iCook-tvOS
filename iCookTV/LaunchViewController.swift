//
//  LaunchViewController.swift
//  TryTVOS
//
//  Created by Ben on 10/04/2016.
//  Copyright © 2016 bcylin.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import UIKit
import Alamofire
import Freddy

class LaunchViewController: UIViewController {

  private lazy var launchImageView: UIImageView = {
    let _imageView = UIImageView()
    _imageView.image = R.image.launchImage()
    _imageView.contentMode = .scaleAspectFill
    return _imageView
  }()

  private lazy var activityIndicator: UIActivityIndicatorView = {
    let _indicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
    _indicator.color = UIColor.Palette.GreyishBrown
    _indicator.hidesWhenStopped = true
    return _indicator
  }()

  private lazy var upperTaglineLabel: UILabel = {
    let _upper = UILabel.taglineLabel()
    _upper.text = R.string.localizable.launchScreenUpperTagline()
    return _upper
  }()

  private lazy var lowerTaglineLabel: UILabel = {
    let _lower = UILabel.taglineLabel()
    _lower.text = R.string.localizable.launchScreenLowerTagline()
    return _lower
  }()

  private var upperTaglineConstraint: NSLayoutConstraint?
  private var lowerTaglineConstraint: NSLayoutConstraint?

  private var isAnimating = false
  private let semaphore = DispatchSemaphore(value: 0)

  private enum Animation {
    static let duration = TimeInterval(0.9)
    static let first = (begin: Double(0), duration: Double(0.6))
    static let second = (begin: Double(0.2), duration: Double(0.7))
  }

  // MARK: - UIViewController

  override func loadView() {
    super.loadView()
    view.backgroundColor = UIColor.tvBackgroundColor()
    view.addSubview(launchImageView)
    view.addSubview(activityIndicator)
    view.addSubview(upperTaglineLabel)
    view.addSubview(lowerTaglineLabel)

    launchImageView.frame = view.bounds
    launchImageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

    activityIndicator.translatesAutoresizingMaskIntoConstraints = false
    upperTaglineLabel.translatesAutoresizingMaskIntoConstraints = false
    lowerTaglineLabel.translatesAutoresizingMaskIntoConstraints = false

    activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 5).isActive = true
    activityIndicator.topAnchor.constraint(equalTo: view.centerYAnchor, constant: 110).isActive = true

    upperTaglineConstraint = upperTaglineLabel.topAnchor.constraint(equalTo: activityIndicator.bottomAnchor, constant: 100)
    upperTaglineConstraint?.isActive = true
    upperTaglineLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true

    lowerTaglineConstraint = lowerTaglineLabel.topAnchor.constraint(equalTo: upperTaglineLabel.bottomAnchor, constant: 100)
    lowerTaglineConstraint?.isActive = true
    lowerTaglineLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    activityIndicator.startAnimating()
    fetchCategories()
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)

    isAnimating = true
    UIView.animateKeyframes(withDuration: Animation.duration, delay: 0, options: [], animations: {
      UIView.addKeyframe(withRelativeStartTime: Animation.first.begin, relativeDuration: Animation.first.duration) {
        self.upperTaglineLabel.alpha = 1
        self.upperTaglineConstraint?.constant = 40
        self.view.layoutIfNeeded()
      }
      UIView.addKeyframe(withRelativeStartTime: Animation.second.begin, relativeDuration: Animation.second.duration) {
        self.lowerTaglineLabel.alpha = 1
        self.lowerTaglineConstraint?.constant = 0
        self.view.layoutIfNeeded()
      }
    }) { _ in
      self.semaphore.signal()
      self.isAnimating = false
    }
  }

  // MARK: - Private Methods

  private func fetchCategories() {
    Alamofire.request(iCookTVKeys.baseAPIURL + "categories.json", method: .get).responseJSON { [weak self] response in
      guard let data = response.data, response.result.error == nil else {
        self?.showAlert(response.result.error)
        return
      }

      do {
        Debug.print(response.result.value)
        let json = try JSON(data: data)
        let categories = try json.getArray(at: "data").map(Category.init)
        let showCategories: () -> Void = {
          self?.navigationController?.setViewControllers([CategoriesViewController(categories: categories)], animated: true)
        }

        if let this = self, this.isAnimating {
          // Wait until the animation finishes
          DispatchQueue.global().async {
            _ = this.semaphore.wait(timeout: Animation.duration.dispatchTime)
            DispatchQueue.main.async(execute: showCategories)
          }
        } else {
          showCategories()
        }
      } catch {
        self?.showAlert(error, retry: self?.fetchCategories)
      }
    }
  }

}


////////////////////////////////////////////////////////////////////////////////


private extension UILabel {

  class func taglineLabel() -> UILabel {
    let label = UILabel()
    label.font = UIFont.tvFontForTagline()
    label.textColor = UIColor.tvTaglineColor()
    label.textAlignment = .center
    label.numberOfLines = 0
    label.alpha = 0
    return label
  }

}


private extension TimeInterval {

  var dispatchTime: DispatchTime {
    return DispatchTime.now() + Double(Int64(self * 1e+9)) / Double(NSEC_PER_SEC)
  }

}
