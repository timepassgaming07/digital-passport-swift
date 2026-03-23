import SwiftUI

struct AmbientBackground: View {
    var isDark: Bool = true
    var body: some View {
        if isDark { DarkBackground() } else { LightBackground() }
    }
}

private struct DarkBackground: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 0.04)) { tl in
            let t = tl.date.timeIntervalSinceReferenceDate
            ZStack {
                LinearGradient(colors:[
                    Color(red:5/255,green:8/255,blue:28/255),
                    Color(red:8/255,green:12/255,blue:40/255),
                ], startPoint:.topLeading, endPoint:.bottomTrailing).ignoresSafeArea()
                Circle().fill(RadialGradient(colors:[Color(hex:"00D4FF").opacity(0.75),.clear],center:.center,startRadius:0,endRadius:200))
                    .frame(width:380).offset(x:-95+CGFloat(sin(t*0.17))*30,y:-160+CGFloat(cos(t*0.13))*26)
                    .blur(radius:55).ignoresSafeArea()
                Circle().fill(RadialGradient(colors:[Color(hex:"7C3AED").opacity(0.70),.clear],center:.center,startRadius:0,endRadius:220))
                    .frame(width:420).offset(x:148+CGFloat(cos(t*0.11))*28,y:290+CGFloat(sin(t*0.15))*22)
                    .blur(radius:60).ignoresSafeArea()
                Circle().fill(RadialGradient(colors:[Color(hex:"2563EB").opacity(0.45),.clear],center:.center,startRadius:0,endRadius:180))
                    .frame(width:360).offset(x:CGFloat(sin(t*0.09))*20,y:80+CGFloat(cos(t*0.12))*18)
                    .blur(radius:50).ignoresSafeArea()
            }
        }
    }
}

private struct LightBackground: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 0.04)) { tl in
            let t = tl.date.timeIntervalSinceReferenceDate
            ZStack {
                // Pearl blue-grey base — exact match to reference image
                LinearGradient(colors:[
                    Color(red:210/255,green:225/255,blue:240/255),
                    Color(red:195/255,green:215/255,blue:235/255),
                    Color(red:220/255,green:232/255,blue:245/255),
                ], startPoint:.topLeading, endPoint:.bottomTrailing).ignoresSafeArea()

                // Soft cyan shimmer
                Circle().fill(RadialGradient(colors:[Color(hex:"BAE6FD").opacity(0.60),.clear],center:.center,startRadius:0,endRadius:200))
                    .frame(width:380).offset(x:-80+CGFloat(sin(t*0.17))*22,y:-150+CGFloat(cos(t*0.13))*18)
                    .blur(radius:65).ignoresSafeArea()

                // Soft lavender
                Circle().fill(RadialGradient(colors:[Color(hex:"C4B5FD").opacity(0.45),.clear],center:.center,startRadius:0,endRadius:200))
                    .frame(width:380).offset(x:140+CGFloat(cos(t*0.11))*20,y:270+CGFloat(sin(t*0.15))*18)
                    .blur(radius:70).ignoresSafeArea()

                // White highlight centre
                Circle().fill(RadialGradient(colors:[Color.white.opacity(0.70),.clear],center:.center,startRadius:0,endRadius:160))
                    .frame(width:300).offset(x:CGFloat(sin(t*0.09))*15,y:70+CGFloat(cos(t*0.12))*14)
                    .blur(radius:50).ignoresSafeArea()

                // Soft blue bottom
                Circle().fill(RadialGradient(colors:[Color(hex:"93C5FD").opacity(0.35),.clear],center:.center,startRadius:0,endRadius:150))
                    .frame(width:280).offset(x:-130+CGFloat(cos(t*0.08))*14,y:360+CGFloat(sin(t*0.10))*16)
                    .blur(radius:45).ignoresSafeArea()
            }
        }
    }
}
extension View {
    func ambientBackground() -> some View {
        ZStack { AmbientBackground(); self }
    }
}
