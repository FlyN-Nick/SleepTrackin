//
//  ViewController.swift
//  SleepTrackin
//
//  Created by Nicholas Assaderaghi on 5/1/20.
//  Copyright © 2020 Liege LLC. All rights reserved.
//

import UIKit
import Firebase
import Foundation
import AVKit
import CoreTelephony
import SystemConfiguration

class ViewController: UIViewController
{
    @IBOutlet weak var StartingTime: UIDatePicker!
    @IBOutlet weak var StoppingTime: UIDatePicker!
    private let reachability = SCNetworkReachabilityCreateWithName(nil, "google.com")

    override func viewDidLoad()
    {
        super.viewDidLoad()
        let today = Date()
        StoppingTime.maximumDate = today
        StartingTime.minimumDate = today.addingTimeInterval(-48*60*60)
        StoppingTime.minimumDate = today.addingTimeInterval(-48*60*60+60)
        StartingTime.maximumDate = today.addingTimeInterval(-60)
        checkReachable()
    }
    private func checkReachable()
    {
        var flags = SCNetworkReachabilityFlags()
        SCNetworkReachabilityGetFlags(self.reachability!, &flags)
        if (!isNetworkReachable(with: flags))
        {
            let alert = UIAlertController(title: "Internet Connection Required", message: "You can turn on mobile data for this app in Settings.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    private func isNetworkReachable (with flags: SCNetworkReachabilityFlags) -> Bool
    {
        let isReachable = flags.contains(.reachable)
        let needsConnection = flags.contains(.connectionRequired)
        let canConnectAutomatically = flags.contains(.connectionOnDemand) || flags.contains(.connectionOnTraffic)
        let canConnectWithoutUserInteraction = canConnectAutomatically && !flags.contains(.interventionRequired)
        return isReachable && (!needsConnection || canConnectWithoutUserInteraction)
    }
    @IBAction func startingTimeChanged(_ sender: UIDatePicker)
    {
        let startingDate = sender.date
        let minimumDate = startingDate.addingTimeInterval(60)
        StoppingTime.minimumDate = minimumDate
        //StoppingTime.minimumDate = nil
        let today = Date()
        StoppingTime.minimumDate = today.addingTimeInterval(-48*60*60+60)
    }
    @IBAction func stoppingTimeChanged(_ sender: UIDatePicker)
    {
        let stoppingDate = sender.date
        let maximumDate = stoppingDate.addingTimeInterval(-60)
        StartingTime.maximumDate = maximumDate
        //StartingTime.maximumDate = nil
        let today = Date()
        StartingTime.maximumDate = today.addingTimeInterval(-60)
        
    }
    @IBAction func SubmitButton(_ sender: Any)
    {
        checkReachable()
        let dataReference = Firestore.firestore().collection("stats").document()
        let data = [
            "Date": Date().stripTime(),
            "StartTime": StartingTime.date,
            "StopTime": StoppingTime.date
            ] as [String : Any]
        dataReference.setData(data, completion: {(err) in
                if err != nil
                {
                    print("Error while uploading sleep data: \(String(describing: err))")
                    let alert = UIAlertController(title: "Something Went Wrong", message: "An error occured while uploading to the database.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                    return
                }
                else
                {
                    let storyboard = UIStoryboard(name: "Second", bundle: nil)
                    let vc = storyboard.instantiateViewController(withIdentifier: "SecondViewController") as! SecondViewController
                    vc.modalPresentationStyle = .fullScreen
                    vc.modalTransitionStyle = .crossDissolve
                    self.present(vc, animated: true)
                }
            })
    }
    @IBAction func ResultsButton(_ sender: Any)
    {
        let storyboard = UIStoryboard(name: "Second", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "SecondViewController") as! SecondViewController
        vc.modalPresentationStyle = .fullScreen
        vc.modalTransitionStyle = .crossDissolve
        self.present(vc, animated: true)
    }
}
extension Date
{
    func stripTime() -> Date
    {
        let components = Calendar.current.dateComponents([.year, .month, .day], from: self)
        let date = Calendar.current.date(from: components)
        return date!
    }
}

