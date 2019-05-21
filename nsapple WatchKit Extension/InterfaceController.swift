//
//  InterfaceController.swift
//  nsapple WatchKit Extension
//
//  Created by Kenneth Stack on 7/9/15.
//  Copyright (c) 2015 Perceptus.org. All rights reserved.
//

import WatchKit
import Foundation



let defaults = UserDefaults(suiteName:"group.com.nsapple")
let mmol = defaults?.bool(forKey: "mmol") ?? false
let urlUser = defaults?.string(forKey: "name_preference") ?? "No User URL"


public struct watch {
    
    public static var screenWidth: CGFloat {
        return WKInterfaceDevice.current().screenBounds.width
    }
    
    public static var is38: Bool {
        return screenWidth == 136
    }
    
    public static var is42: Bool {
        return screenWidth == 156
    }
}



class InterfaceController: WKInterfaceController {
   
    @IBOutlet weak var bgGraph: WKInterfaceImage!
    @IBOutlet weak var primaryBG: WKInterfaceLabel!
    @IBOutlet weak var bgDirection: WKInterfaceLabel!
    @IBOutlet weak var deltaBG: WKInterfaceLabel!
    @IBOutlet weak var minAgo: WKInterfaceLabel!
    @IBOutlet weak var graphHours: WKInterfaceLabel!
    @IBOutlet weak var hourSlider: WKInterfaceSlider!
    @IBOutlet var statusOverride: WKInterfaceLabel!
    @IBOutlet var loopStatus2: WKInterfaceLabel!
    @IBOutlet var loopStatus1: WKInterfaceLabel!
    @IBOutlet weak var prediction: WKInterfaceLabel!
    @IBOutlet weak var velocity: WKInterfaceLabel!
    @IBOutlet var errorDisplay: WKInterfaceLabel!
    var graphlength:Int=3
    var bghistread=true as Bool
    var bghist = [entriesData]()
    var responseDict=[:] as [String:AnyObject]
   
    @IBAction func hourslidervalue(_ value: Float) {
        let slidermap:[Int:Int]=[1:24,2:12,3:6,4:3,5:1]
        let slidervalue=Int(round(value*1000)/1000)
        graphlength=slidermap[slidervalue]!
        loadData()
        
    }

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
  
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
   
        super.willActivate()
        loadData()
       // updateBG()
       // updatepumpstats()
        
        
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        let gray=UIColor.gray as UIColor
        self.primaryBG.setTextColor(gray)
        self.bgDirection.setTextColor(gray)
        self.prediction.setTextColor(gray)
        self.velocity.setTextColor(gray)
        self.minAgo.setTextColor(gray)
        self.deltaBG.setTextColor(gray)
        self.loopStatus1.setTextColor(gray)
        self.loopStatus2.setTextColor(gray)
        self.statusOverride.setTextColor(gray)
        //to do add blank image and set on sleep
        super.didDeactivate()
    }
    
    func updatepumpstats2(json: [[String:AnyObject]]) {
        
        print("in updatePump")

            
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withFullDate,
                                       .withTime,
                                       .withDashSeparatorInDate,
                                       .withColonSeparatorInTime]
            
            
            
        if json.count == 0 {
                self.loopStatus1.setText("No Records")
                return}
            

        //only grabbing one record since ns sorts by created_at : -1
        let lastdata = json[0] as [String : AnyObject]?
            
            
            
            //pump and uploader
            
            var pstatus:String = "Res "
            let lastpump = lastdata?["pump"] as! [String : AnyObject]?
            if lastpump != nil {
                if let pumptime = formatter.date(from: (lastpump?["clock"] as! String))?.timeIntervalSince1970  {
                    self.labelColor(label: self.loopStatus1, timeSince: pumptime)
                    if let res = lastpump?["reservoir"] as? Double
                    {
                        pstatus = pstatus + String(format:"%.0f", res)
                    }
                        
                    else
                        
                    {
                        pstatus = pstatus + "N/A"
                    }
                    
                    if let uploader = lastdata?["uploader"] as? [String:AnyObject] {
                        let upbat = uploader["battery"] as! Double
                        pstatus = pstatus + " UpBat " + String(format:"%.0f", upbat)
                    }
                    
                    //add back if loop ever uploads again
                    //                        if let riley = lastpump["radioAdapter"] as? [String:AnyObject] {
                    //                            if let rrssi = riley["RSSI"] as? Int {
                    //                                pstatus = pstatus + "%  RdB " + String(rrssi)
                    //                            }
                    //                        }
                    
                }
                
            } //finish pump data
                
            else
                
            {
                pstatus = "Pump Record Error"
            }
            
            //
            
            //loop
            let lastloop = lastdata?["loop"] as! [String : AnyObject]?
            var pstatus2:String = " IOB "
            if lastloop != nil {
                if let looptime = formatter.date(from: (lastloop?["timestamp"] as! String))?.timeIntervalSince1970  {
                    self.labelColor(label: self.loopStatus2, timeSince: looptime)
                    if let failure = lastloop?["failureReason"] {
                        self.loopStatus1.setText(pstatus)
                        //pstatus2 = "Loop Failure " + (failure as! String)
                        self.loopStatus2.setTextColor(UIColor.red)
                        pstatus2 = "Loop Failure"
                        self.errorDisplay.setTextColor(UIColor.red)
                        self.errorDisplay.setText(failure as? String)
                    }
                    else
                    {
                        self.errorDisplay.setText("")
                        self.loopStatus2.setTextColor(UIColor.green)
                        if let enacted = lastloop?["enacted"] as? [String:AnyObject] {
                            if let tempbasal = enacted["rate"] as? Double {
                                pstatus = pstatus + " Basal " + String(format:"%.1f", tempbasal)
                                self.loopStatus1.setText(pstatus)
                            }
                        }
                        if let iobdata = lastloop?["iob"] as? [String:AnyObject] {
                            pstatus2 = pstatus2 + String(format:"%.1f", iobdata["iob"] as! Double)
                        }
                        if let cobdata = lastloop?["cob"] as? [String:AnyObject] {
                            pstatus2 = pstatus2 + "  COB " + String(format:"%.0f", cobdata["cob"] as! Double) + " EBG "
                        }
                        if let predictdata = lastloop?["predicted"] as? [String:AnyObject] {
                            let prediction = predictdata["values"] as! [Double]
                            pstatus2 = pstatus2 + self.bgOutput(bg: prediction.last!, mmol: mmol)
                            
                            
                        }
                        
                    }
                }
                
                
            } //finish loop
                
            else
                
            {
                pstatus2 = "Loop Record Error"
            }
            
            self.loopStatus2.setText(pstatus2)
            
            //overrides
            var pstatus3 = "" as String
            if let lastoverride = lastdata?["override"] as! [String : AnyObject]? {
                
                
                
                if let overridetime = formatter.date(from: (lastoverride["timestamp"] as! String))?.timeIntervalSince1970  {
                    self.labelColor(label: self.statusOverride, timeSince: overridetime)
                } //finish color
                if lastoverride["active"] as! Bool {
                    let currentCorrection  = lastoverride["currentCorrectionRange"] as! [String: AnyObject]
                    pstatus3 = "BGTargets("
                    let minValue = currentCorrection["minValue"] as! Double
                    let maxValue = currentCorrection["maxValue"] as! Double
                    
                    pstatus3 = pstatus3 + self.bgOutput(bg: minValue, mmol: mmol) + ":" + self.bgOutput(bg: maxValue, mmol: mmol) + ") M:"
                    let multiplier = lastoverride["multiplier"] as! Double
                    pstatus3 = pstatus3 + String(format:"%.1f", multiplier)
                }
                
                
            } //if let for override - older versions dont have an overide field
            
            self.statusOverride.setText(pstatus3)
            
            
            

        
        print("end updatePump")
    }
    

    
    func bgOutput(bg: Double, mmol: Bool) -> String {
        if !mmol {
            return String(format:"%.0f", bg)
        }
        else
        {
            return String(format:"%.1f", bg / 18.6)
        }
    }
    
    func velocityOutput(v: Double, mmol: Bool) -> String {
        if !mmol {
            return String(format:"%.1f", v)
        }
        else
        {
            return String(format:"%.1f", v / 18.6)
        }
    }
    
    func labelColor(label: WKInterfaceLabel, timeSince: TimeInterval) {
        let ct=TimeInterval(Date().timeIntervalSince1970)
        let deltat=(ct-timeSince)/60
        
        if deltat<6
            {label.setTextColor(UIColor.green)}
        else
        if deltat<14
            {label.setTextColor(UIColor.yellow)}
        else
            {label.setTextColor(UIColor.red)}
             
        return
        }

    
    struct sgvData: Codable {
        var sgv: String
        var datetime: TimeInterval
        var direction: String
    }
    struct dataPebble: Codable{
        var bgs: [sgvData]
        
    }
    struct entriesData: Codable {
        var sgv: Int
        var date: TimeInterval
        var direction: String
    }
    
    func loadData () {
        print("in load BG")
     
        let points = String(self.graphlength * 12 + 1)
    

        let urlPath: String = urlUser + "/pebble?count=" + points
        guard let url2 = URL(string: urlPath) else {
            
            self.primaryBG.setText("")
            self.velocity.setText("URL ERROR")
            return
        }

        let getBGTask = URLSession.shared.dataTask(with: url2) { data, response, error in
            
            print("start bg url")
            guard error == nil else {
                self.primaryBG.setText("")
                self.velocity.setText(error?.localizedDescription)
                return
            }
            guard let data = data else {
                self.primaryBG.setText("")
                self.velocity.setText("No Data")
                return
            }
            let decoder = JSONDecoder()
            let entries2 = try? decoder.decode(dataPebble.self, from: data)
            if let entries2 = entries2 {
            self.updateBG2(entries2: entries2)
            }
            else
            {
                self.primaryBG.setText("")
                self.velocity.setText("BG Decoding Error")
                return
            }
            }
        getBGTask.resume()
        
        
        let urlPath2 = urlUser + "/api/v1/devicestatus.json?count=1"
        let escapedAddress = urlPath2.addingPercentEncoding(withAllowedCharacters:NSCharacterSet.urlQueryAllowed)
        
        guard let urlpump = URL(string: escapedAddress!) else {
            
            loopStatus1.setText("")
            loopStatus1.setText("URL ERROR")
            return
        }

        print("entered 2nd task")
        let task3 = URLSession.shared.dataTask(with: urlpump) { data, response, error in
            print("in pudate pump")
            guard error == nil else {
                
                self.loopStatus1.setText(error?.localizedDescription)
                return
            }
            guard let data = data else {
                
                self.loopStatus1.setText("Data is Empty")
                return
            }
            
            let json = try? JSONSerialization.jsonObject(with: data) as! [[String:AnyObject]]
           
            if let json = json {
                self.updatepumpstats2(json: json)
            }
            
            else
            
            {
                self.loopStatus1.setText("")
                self.loopStatus1.setText("Pump Stat Decoding Error")
                return
            }
            print("finish pump update")
 
        }
        task3.resume()
        

        
    }
    
    func updateBG2 (entries2: dataPebble) {
        print("in update BG")
        //set bg color to something old so we know if its not really updating
        let gray=UIColor.gray as UIColor
        
        //toDO remove this and make sure if there is no data / errors things get greyed its wasting time
//        self.primarybg.setTextColor(gray)
//        self.bgdirection.setTextColor(gray)
//        self.plabel.setTextColor(gray)
//        self.vlabel.setTextColor(gray)
//        self.minago.setTextColor(gray)
//        self.deltabg.setTextColor(gray)
        var entries = [entriesData]()
       
            var j: Int = 0
            
            //cast string sgvs to int
            //to do there must be a simpler way ......
            while j < entries2.bgs.count {
                entries.append(entriesData(sgv: Int(entries2.bgs[j].sgv) ?? 0, date: entries2.bgs[j].datetime, direction: entries2.bgs[j].direction ))
                j=j+1
            }
            
            //successfully received pebble end point data
            
            if entries.count > 0 {
                
                self.bghistread=true
                let cbg=entries[0].sgv
                let priorbg = entries[1].sgv
                let direction=entries[0].direction
                let dbg = cbg - priorbg as Int
                let bgtime=entries[0].date
                let red=UIColor.red as UIColor
                //save as global variables
                self.bghist=entries

                self.labelColor(label: self.minAgo, timeSince: bgtime)
                let deltat=(TimeInterval(Date().timeIntervalSince1970)-bgtime/1000)/60
                self.minAgo.setText(String(Int(deltat))+" min ago")
                
                if (cbg<40) {
                    self.primaryBG.setTextColor(red)
                    self.primaryBG.setText(errorcode(cbg))
                    self.bgDirection.setText("")
                    self.deltaBG.setText("")
                }
                    
                else
                    
                {
                    self.primaryBG.setTextColor(bgcolor(cbg))
                    self.primaryBG.setText(self.bgOutput(bg: Double(cbg), mmol: mmol))
                    self.bgDirection.setText(dirgraphics(direction))
                    self.bgDirection.setTextColor(bgcolor(cbg))
                    let velocity=velocity_cf(entries) as Double
                    let prediction=velocity*30.0+Double(cbg)
                    self.deltaBG.setTextColor(UIColor.white)
                    if dbg < 0 {
                        self.deltaBG.setText(self.bgOutput(bg: Double(dbg), mmol: mmol) + " mg/dl")
                    }
                    else
                    {
                        self.deltaBG.setText("+"+self.bgOutput(bg: Double(dbg), mmol: mmol)+" mg/dl")
                    }
                    
                    self.velocity.setText(self.velocityOutput(v: velocity, mmol: mmol))
                    self.prediction.setText(self.bgOutput(bg: prediction, mmol: mmol))
                    
                }
                
                
            } //end bgs !=nil
                
                //did not get pebble endpoint data
            else
            {
                self.bghistread=false
                noconnection()
                return
            }
        
        createGraph(hours: self.graphlength, bghist: entries)
         
            
 
        print("end update bg")
    }

    
    func createGraph(hours:Int, bghist:[entriesData]) {
        // create graph
        
        // Create a graphics context
        let height : CGFloat = 101
        let width = self.contentFrame.size.width
        let size = CGSize(width:width, height:height)

        UIGraphicsBeginImageContext(size)
        let context = UIGraphicsGetCurrentContext()
        context!.setLineWidth(1.0)
        
        var xdata = [Double]()
        var ydata = [Double]()
        var colorData = [UIColor]()
        var miny : Double
        var maxy: Double
        
        //ydata is scaled to 100
        //xdata is scaled to width
        //creatre stand alone scatter plot package that takes generic data of this form
        //3 arrays - xdata, ydata, color, y min and max, x min and max
        //get the scaled data
        (xdata, ydata, colorData, miny, maxy) = self.bgScaling(hours, bghist: bghist, width: width)
        
        //create data points
        var i: Int = 0
        let leftbuffer : Double = 20
        let widthD : Double = Double(width)
        while i < xdata.count {
            //reverse y data, rescale x for leftbuffer
            ydata[i] = 100.0 - ydata[i]
            xdata[i] = (widthD - leftbuffer) / widthD * xdata[i] + leftbuffer
            context!.setStrokeColor(colorData[i].cgColor)
            let rect = CGRect(x: CGFloat(xdata[i]), y: CGFloat(ydata[i]), width: width/2/100, height: 50/100)
            context?.addEllipse(in: rect)
            context?.drawPath(using: .fillStroke)
            i=i+1
        }
        
        //draw horizontal lines at 80 and 180 for xcontext
        //to do make user configurable
        
        //draw high and low bound bars
        let lowLimit : CGFloat = 80
        let highLimit : CGFloat = 180
        let topBound : CGFloat = 100 - (highLimit - CGFloat(miny))/(CGFloat(maxy) - CGFloat(miny)) * 100
        let bottomBound : CGFloat = 100 - (lowLimit - CGFloat(miny))/(CGFloat(maxy) - CGFloat(miny)) * 100
        context?.setStrokeColor(UIColor.white.cgColor)
        context?.setLineWidth(2)
        context?.move(to: CGPoint(x: CGFloat(leftbuffer),y: topBound+1))
        context?.addLine(to: CGPoint(x: width, y: topBound+1))
        context?.move(to: CGPoint(x: CGFloat(leftbuffer),y: bottomBound-1))
        context?.addLine(to: CGPoint(x: width, y: bottomBound-1))
        //draw outline if outline isnt set by low or high limit bars
        context?.setLineWidth(1)
        if (abs(miny - Double(lowLimit)) > 5 ) {
            context?.move(to: CGPoint(x: CGFloat(leftbuffer),y: height))
            context?.addLine(to: CGPoint(x: width, y: height))
        }
        
        if (abs(maxy - Double(highLimit)) > 5 ) {
            context?.move(to: CGPoint(x: CGFloat(leftbuffer),y: 0))
            context?.addLine(to: CGPoint(x: width, y: 0))
        }
        context!.strokePath();
        //draw vertical dashedlines on hour marks
        context?.setStrokeColor(UIColor.gray.cgColor)
        context?.setLineDash(phase: 4, lengths: [4])
        context?.move(to:CGPoint(x: CGFloat(leftbuffer), y: 0))
        context?.addLine(to: CGPoint(x: CGFloat(leftbuffer), y: height))
        context?.move(to:CGPoint(x: width-1, y: 0))
        context?.addLine(to: CGPoint(x: width-1, y: height))
        
        i=1
        while i < hours {
            let ratio : CGFloat = CGFloat(Double(i)/Double(hours))
            let xvert : CGFloat = width*ratio
            context?.move(to:CGPoint(x: (width - CGFloat(leftbuffer))*xvert/width + CGFloat(leftbuffer), y: 0))
            context?.addLine(to: CGPoint(x: (width - CGFloat(leftbuffer))*xvert/width + CGFloat(leftbuffer), y: height))
            i=i+1
        }
        context!.strokePath();
        
        
        //labels
        let ybuffer : CGFloat = 5
        let xbuffer : CGFloat = 9
        //round to 5's or mgdl, 0.2 for mmol/L
        var rounder : Double = 5
        if mmol {rounder = 0.2}
        self.drawText(context: context, text: self.bgOutput(bg: round(miny/rounder) * rounder, mmol: mmol ) as NSString, centreX: 0 + xbuffer, centreY: height - ybuffer)
        self.drawText(context: context, text: self.bgOutput(bg: round(maxy/rounder) * rounder, mmol: mmol ) as NSString, centreX: 0 + xbuffer, centreY: ybuffer + 1 )
        self.drawText(context: context, text: self.bgOutput(bg: round((maxy + miny) / (2.0 * rounder)) * rounder, mmol: mmol ) as NSString, centreX: 0 + xbuffer, centreY: height/2)
        
        
        
        // Draw and Convert to UIImage
        
        let cgimage = context!.makeImage();
        let uiimage = UIImage(cgImage: cgimage!)
        
        // End the graphics context
        UIGraphicsEndImageContext()
     DispatchQueue.main.async() {
        self.bgGraph.setImage(uiimage)
        }
    }
    
    
    
    func drawText( context : CGContext?, text : NSString, centreX : CGFloat, centreY : CGFloat )
    {
        let attributes = [
            NSAttributedStringKey.font : UIFont.systemFont(ofSize: 12, weight: UIFont.Weight.thin),
            NSAttributedStringKey.foregroundColor : UIColor.white
        ]
        
        let textSize = text.size( withAttributes: attributes )
        
        text.draw(
            in: CGRect( x: centreX - textSize.width / 2.0,
                        y: centreY - textSize.height / 2.0,
                        width: textSize.width,
                        height: textSize.height + 2),
            withAttributes : attributes )
    }
    
    func velocity_cf(_ bgs:[entriesData])->Double {
    //linear fit to 3 data points get slope (ie velocity)
    var v=0 as Double
    var n=0 as Int
    var i=0 as Int
    let ONE_MINUTE=60000.0 as Double
    var bgsgv = [Double](repeating: 0.0, count: 4)
        var date = [Double](repeating: 0.0, count: 4)
        
      
        i=0
        while i<4 {
         date[i] = bgs[i].date
            bgsgv[i] = Double(bgs[i].sgv)
            i=i+1
          
        }
        
        
    if ((date[0]-date[3])/ONE_MINUTE < 15.1) {n=4}
        
        else
        
    if ((date[0]-date[2])/ONE_MINUTE < 10.1) {n=3}
    else
        
    if ((date[0]-date[1])/ONE_MINUTE<10.1) {n=2}
    else {n=0}
        
    var xm=0.0 as Double
    var ym=0.0 as Double
    if (n>0) {
        var j=0;
    while j<n {
				
				xm = xm + date[j]/ONE_MINUTE
				ym = ym + bgsgv[j]
                j=j+1
    }
    xm=xm/Double(n)
    ym=ym/Double(n)
    var c1=0.0 as Double
    var c2=0.0 as Double
    var t=0.0 as Double
    j=0
    while (j<n) {
				
				t=date[j]/ONE_MINUTE
				c1=c1+(t-xm)*(bgsgv[j]-ym)
				c2=c2+(t-xm)*(t-xm)
                j=j+1
    }
    v=c1/c2

    }
    //need to decide what to return if there isnt enough data
    
    else {v=0}
    
    return v
    }
  
    func noconnection() {
        deltaBG.setTextColor(UIColor.red)
        deltaBG.setText("No Data")
        
    }
    
    func bgcolor(_ value:Int)->UIColor
    {
        
        let red=UIColor.red as UIColor
        let green=UIColor.green as UIColor
        let yellow=UIColor.yellow as UIColor
        var sgvcolor=green as UIColor
        
        if (value<65) {sgvcolor=red}
        else
            if(value<80) {sgvcolor=yellow}
                
            else
                if (value<180) {sgvcolor=green}
                    
                else
                    if (value<250) {sgvcolor=yellow}
                    else
                    {sgvcolor=red}
        return sgvcolor
    }
    
    func errorcode(_ value:Int)->String {
        
       let errormap=["EC0 UNKNOWN","EC1 SENSOR NOT ACTIVE","EC2 MINIMAL DEVIATION","EC3 NO ANTENNA","EC4 UNKNOWN","EC5 SENSOR CALIBRATION","EC6 COUNT DEVIATION","EC7 UNKNOWN","EC8 UNKNWON","EC9 HOURGLASS DEVIATION","EC10 ??? POWER DEVIATION","EC11 UNKNOWN","EC12 BAD RF","EC13 MH"]

        return errormap[value]
    }
    
    func dirgraphics(_ value:String)->String {
         let graphics:[String:String]=["Flat":"\u{2192}","DoubleUp":"\u{21C8}","SingleUp":"\u{2191}","FortyFiveUp":"\u{2197}\u{FE0E}","FortyFiveDown":"\u{2198}\u{FE0E}","SingleDown":"\u{2193}","DoubleDown":"\u{21CA}","None":"-","NOT COMPUTABLE":"-","RATE OUT OF RANGE":"-"]
        
        
        return graphics[value]!
    }
    
 
    
    func test(_ a:Double,b:Double) ->Int {
        return Int(a+b)
    }
    

    
    func bgScaling(_ hours:Int,bghist:[entriesData], width: CGFloat)-> ([Double], [Double], [UIColor], Double, Double) {


        let ct2=NSInteger(Date().timeIntervalSince1970)

        var maxy=0
        var maxx=0
        var miny=1000
        var minx=1000000
        let bgth=180
        let bgtl=80

        var gpoints=0 as Int
        var bgtimes = [Int]()
        let minutes=hours*60
        var inc:Int=1
        if (hours==3||hours==1) {inc=1} else
            if hours==6 {inc=2} else
                if hours==12 {inc=3} else
                {inc=5}
       
        //find max and min time, min and max bg
        var i=0 as Int;

        while (i<bghist.count) {
            let curdate: Double = (bghist[i].date)/1000
            bgtimes.append(Int((Double(minutes)-(Double(ct2)-curdate)/(60.0))))

            if (bgtimes[i]>=0) {
                gpoints += 1
                if (bgtimes[i]>maxx) {maxx=bgtimes[i]}
                if (bgtimes[i]<minx) {minx=bgtimes[i]}
                let bgi = bghist[i].sgv
                if (bghist[i].sgv  > maxy) {maxy = bghist[i].sgv }
                if (bgi < miny) {miny = bgi}
            }
            i=i+1;}
        //insert prediction points into
        if maxy<bgth {maxy=bgth}
        if miny>bgtl {miny=bgtl}
        
        //create strings of data points xg (time) and yg (bg) and string of colors pc
        i=0;
        
        var xdata = [Double] ()
        var ydata = [Double] ()
        var dataColor = [UIColor] ()
        var test = [Int] ()
        
        while i<bghist.count  {
            if (bgtimes[i]>=0) {
                //scale time values
                xdata.append(Double(bgtimes[i])*Double(width)/Double(minutes))
                let sgv:Int = bghist[i].sgv
                test.append(sgv)
                if sgv<60 {dataColor.append(UIColor.red)} else
                    if sgv<80 {dataColor.append(UIColor.yellow)} else
                        if sgv<180 {dataColor.append(UIColor.green)} else
                            if sgv<260 {dataColor.append(UIColor.yellow)} else
                            {dataColor.append(UIColor.red)}
                //scale bg data to 100 is the max
                
                ydata.append(Double((sgv-miny)*100/(maxy-miny)))
 
            }
            i=i+inc}
        
        return (xdata, ydata, dataColor, Double(miny), Double(maxy))
        
        
    }
    
    }


