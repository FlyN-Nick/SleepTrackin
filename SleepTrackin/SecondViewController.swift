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

class SecondViewController: UIViewController
{
    @IBOutlet weak var SuggestionText: UILabel!
    @IBOutlet weak var AverageText: UILabel!
    @IBOutlet weak var LeastText: UILabel!
    @IBOutlet weak var HighestText: UILabel!
    @IBOutlet weak var EarliestText: UILabel!
    @IBOutlet weak var LatestText: UILabel!
    @IBOutlet weak var EarliestWakenText: UILabel!
    @IBOutlet weak var LatestWakenText: UILabel!
    
    private let reachability = SCNetworkReachabilityCreateWithName(nil, "google.com")
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        checkReachable()
        Firestore.firestore().collection("stats")
            .getDocuments() { (querySnapshot, err) in
                if let err = err
                {
                    print("Error getting documents: \(err)")
                    let alert = UIAlertController(title: "Something Went Wrong", message: "An error occured while querying to the database.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .default, handler: nil))
                }
                else
                {
                    var index = 0
                    var info = [[String:Any]]()
                    var specialTotal: Double = 0
                    for document in querySnapshot!.documents
                    {
                        index += 1
                        if (index > 7) { break }
                        let Date = (document.data()["Date"] as! Timestamp).dateValue() as Date
                        let StartTime = (document.data()["StartTime"] as! Timestamp).dateValue() as Date
                        let StopTime = (document.data()["StopTime"] as! Timestamp).dateValue() as Date
                        let delta = (StopTime-StartTime)/60/60
                        let data = [
                            "date": Date,
                            "StartTime": StartTime,
                            "StopTime": StopTime,
                            "delta": delta
                            ] as [String : Any]
                        info.append(data)
                        specialTotal += delta
                    }
                    var average: Double = 0
                    var earliestTime: DateComponents? = nil
                    var latestTime: DateComponents? = nil
                    var earliestWakenTime: DateComponents? = nil
                    var latestWakenTime: DateComponents? = nil
                    var highestAmount: Double? = nil
                    var lowestAmount: Double? = nil
                    for stat in info
                    {
                        let amount = stat["delta"] as! Double
                        var StartTimeComponents = Calendar.current.dateComponents([.hour, .minute], from: stat["StartTime"] as! Date)
                        var StopTimeComponents = Calendar.current.dateComponents([.hour, .minute], from: stat["StopTime"] as! Date)
                        var ConvertedHour = StartTimeComponents.hour!-17
                        if (ConvertedHour < 0) { ConvertedHour = 24+ConvertedHour }
                        StartTimeComponents.hour = ConvertedHour
                        var ConvertedWakenHour = StopTimeComponents.hour!-17
                        if (ConvertedWakenHour < 0) { ConvertedWakenHour = 24+ConvertedWakenHour }
                        StopTimeComponents.hour = ConvertedWakenHour
                        if (earliestTime == nil)
                        {
                            earliestTime = StartTimeComponents
                            latestTime = StartTimeComponents
                            earliestWakenTime = StopTimeComponents
                            latestWakenTime = StopTimeComponents
                        }
                        else if (ConvertedHour < earliestTime!.hour!)
                        {
                            earliestTime = StartTimeComponents
                        }
                        else if (ConvertedHour == earliestTime!.hour! && StartTimeComponents.minute! < earliestTime!.minute!)
                        {
                            earliestTime = StartTimeComponents
                        }
                        else if (ConvertedHour > latestTime!.hour!)
                        {
                            latestTime = StartTimeComponents
                        }
                        else if (ConvertedHour == latestTime!.hour! && StartTimeComponents.minute! > latestTime!.minute!)
                        {
                            latestTime = StartTimeComponents
                        }
                        if (ConvertedWakenHour < earliestWakenTime!.hour!)
                        {
                            earliestWakenTime = StopTimeComponents
                        }
                        else if (ConvertedWakenHour == earliestWakenTime!.hour! && StopTimeComponents.minute! < earliestWakenTime!.minute!)
                        {
                            earliestWakenTime = StopTimeComponents
                        }
                        else if (ConvertedWakenHour > latestWakenTime!.hour!)
                        {
                            latestWakenTime = StopTimeComponents
                        }
                        else if (ConvertedWakenHour == latestWakenTime!.hour! && StopTimeComponents.minute! > latestWakenTime!.minute!)
                        {
                            latestWakenTime = StopTimeComponents
                        }
                        average += amount
                        if (highestAmount == nil)
                        {
                            highestAmount = amount
                            lowestAmount = amount
                        }
                        else if (highestAmount! < amount)
                        {
                            highestAmount = amount
                        }
                        else if (lowestAmount! > amount)
                        {
                            lowestAmount = amount
                        }
                    }
                    if (index < 7)
                    {
                        average = average/Double(index)
                    }
                    else
                    {
                        average = average/7
                    }
                    var wantedTotal: Double? = nil
                    if (index < 7)
                    {
                        wantedTotal = 9.25*Double(index+1)
                    }
                    else
                    {
                        wantedTotal = 9.25*7
                    }
                    let neededAmount = wantedTotal!-specialTotal
                    if (neededAmount <= 0)
                    {
                        self.SuggestionText.text = "You've gotten plenty of sleep this week, go to bed whenever!"
                    }
                    else if (neededAmount > 11)
                    {
                        self.SuggestionText.text = "Go to bed as early as possible."
                    }
                    else
                    {
                        let by = 8-neededAmount
                        if (floor(by) == 0)
                        {
                            self.SuggestionText.text = "Go to bed by midnight tonight."
                        }
                        else if (by < 0)
                        {
                            self.SuggestionText.text = "Go to bed by \(Int(floor(12+by)))PM tonight."
                        }
                        else
                        {
                            self.SuggestionText.text = "Go to bed by \(Int(floor(by)))AM tonight."
                        }
                    }
                    self.AverageText.text = "You've gotten an average of \(round(average*100)/100) hours of sleep this week."
                    self.LeastText.text = "The lowest amount of sleep you've gotten was \(round(lowestAmount!*100)/100) hours."
                    self.HighestText.text = "The highest amount of sleep you've gotten was \(round(highestAmount!*100)/100) hours."
                    self.LatestText.text = "The latest you've gone to bed was at \(self.customTimeFormatter(time: latestTime!))."
                    self.EarliestText.text = "The earliest you've gone to bed was at \(self.customTimeFormatter(time: earliestTime!))."
                    self.LatestWakenText.text = "The latest you've waken up was at \(self.customTimeFormatter(time: latestWakenTime!))."
                    self.EarliestWakenText.text = "The earliest you've waken up was at \(self.customTimeFormatter(time: earliestWakenTime!))."
                }
        }
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
    private func convertTimestamp(serverTimestamp: TimeInterval) -> Date
    {
        let x = serverTimestamp / 1000
        let date = NSDate(timeIntervalSince1970: x)
        return date as Date
    }
    private func hourConverter(hour: Int) -> Int
    {
        var converter: [Int:Int] = [:]
        for i in 1...24
        {
            var test = i-17
            if (test < 0) { test = 24+test }
            converter[test] = i
            /*if (i < 12 || i == 24)
            {
                if (i == 24) { print("actual: \(i-12)AM, converted: \(test)") }
                else { print("actual: \(i)AM, converted: \(test)") }
            }
            else { print("actual: \(i-12)PM, converted: \(test)") }*/
        }
        return converter[hour]!
    }
    private func customTimeFormatter(time: DateComponents) -> String
    {
        let hour = hourConverter(hour: time.hour!)
        let minute = time.minute!
        if (hour < 12)
        {
            return "\(hour):\(minute)AM"
        }
        else if (hour == 24)
        {
            return "\(hour-12):\(minute)AM"
        }
        else
        {
            return "\(hour-12):\(minute)PM"
        }
    }
    @IBAction func backButton(_ sender: Any)
    {
        self.dismiss(animated: true)
    }
}
extension Date
{
    static func - (lhs: Date, rhs: Date) -> TimeInterval
    {
        return lhs.timeIntervalSinceReferenceDate - rhs.timeIntervalSinceReferenceDate
    }
}

