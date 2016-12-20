//
//  DarkSkyWeatherService.swift
//  TraxyApp
//
//  Created by Jonathan Engelsma on 12/19/16.
//  Copyright © 2016 Jonathan Engelsma. All rights reserved.
//

import Foundation

let sharedDarkSkyInstance = DarkSkyWeatherService()

class DarkSkyWeatherService: WeatherService {
    
    let API_BASE = "https://api.darksky.net/forecast/"
    
    var urlSession = URLSession.shared
    
    class func getInstance() -> DarkSkyWeatherService {
        return sharedDarkSkyInstance
    }
    
    func getWeatherForDate(date: Date, forLocation location: (Double, Double), completion: @escaping (Weather?) -> Void) {
        let urlStr = API_BASE +  DARK_SKY_WEATHER_API_KEY + "/\(location.0),\(location.1),\(Int(date.timeIntervalSince1970))"
        let url = URL(string: urlStr)
        
        let task = self.urlSession.dataTask(with: url!) {
          (data, response, error) in
            if let error = error {
                print(error.localizedDescription)
            } else if let _ = response {
                let parsedObj : Dictionary<String,AnyObject>?
                do {
                    parsedObj = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? Dictionary<String,AnyObject>
                    
                    var summary : String?
                    var iconName : String?
                    var temperature : Double?
                    if let topLevelObj = parsedObj {
                        if let currently = topLevelObj["currently"] {
                            summary = currently["summary"] as? String
                            iconName = currently["icon"] as? String
                            temperature = currently["temperature"] as? Double
                        }
                    }
                    
                    if let s=summary, let i=iconName, let t=temperature {
                        let weather = Weather(iconName: i, temperature: t, summary: s)
                        completion(weather)
                    } else {
                        completion(nil)
                    }
                    
                    
                }  catch {
                    completion(nil)
                }
            }
        }
        
        task.resume()
    }

    
}
