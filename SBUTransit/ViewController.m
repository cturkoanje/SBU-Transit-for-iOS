//
//  ViewController.m
//  SBUTransit
//
//  Created by Chrstian Turkoanje on 5/21/13.
//  Copyright (c) 2013 Christian Turkoanje. All rights reserved.
//

#import "ViewController.h"

#define kBgQueue dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0) //1

@interface ViewController ()

@end

@implementation ViewController
{
    GMSMapView *mapView_;
    NSMutableArray *busMarkers;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:40.9156161
                                                            longitude:-73.1239215
                                                                 zoom:14];
    mapView_ = [GMSMapView mapWithFrame:CGRectZero camera:camera];
    mapView_.myLocationEnabled = YES;
    self.view = mapView_;
    
    int routeNumber = 4;
    
    dispatch_async(kBgQueue, ^{
        NSData* data = [NSData dataWithContentsOfURL: [NSURL URLWithString: [NSString stringWithFormat:@"http://beta.ctthosting.com/sbu/route_info/?id=%d", routeNumber]]];
        [self performSelectorOnMainThread:@selector(setRouteOnMap:) withObject:data waitUntilDone:YES];
    });
    
    [self setRouteOnMap:nil];
    
}

-(void)setRouteOnMap:(NSData*)routeData {
    
    NSString *strData = [[NSString alloc]initWithData:routeData encoding:NSUTF8StringEncoding];
    NSData *data = [strData dataUsingEncoding:NSUTF8StringEncoding];
    NSError* error;
    NSArray* json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    NSDictionary* routeInfo = [json objectAtIndex:0];
    NSArray* routeList = [json objectAtIndex:1];
    int routeIDNumber = [[routeInfo objectForKey:@"id"] intValue];
    
    NSLog( @"%@",json);
    NSLog( @"%@", error);
    
    GMSPolyline *polyline = [[GMSPolyline alloc] init];
    GMSMutablePath *path = [GMSMutablePath path];
    
    for (NSDictionary *object in routeList) {
        float lat = [[object objectForKey:@"lat"] floatValue];
        float lon = [[object objectForKey:@"lon"] floatValue];
        [path addCoordinate:CLLocationCoordinate2DMake(lat, lon)];
    }

    
    polyline.path = path;
    polyline.strokeColor = [self colorFromHexString:[NSString stringWithFormat:@"%@", [routeInfo objectForKey:@"color"]]];
    polyline.strokeWidth = 3.f;
    polyline.map = mapView_;
    
    dispatch_async(kBgQueue, ^{
        NSData* data = [NSData dataWithContentsOfURL: [NSURL URLWithString: [NSString stringWithFormat:@"http://beta.ctthosting.com/sbu/get_stops_by_id/?id=%d", routeIDNumber]]];
        [self performSelectorOnMainThread:@selector(setStopsOnMap:) withObject:data waitUntilDone:YES];
    });
    dispatch_async(kBgQueue, ^{
        [self updateBusData:routeIDNumber];
    });
     
}

//_________________________________________________________________________________________________

-(void)setStopsOnMap:(NSData*)routeData {
    NSString *strData = [[NSString alloc]initWithData:routeData encoding:NSUTF8StringEncoding];
    NSData *data = [strData dataUsingEncoding:NSUTF8StringEncoding];
    NSError* error;
    NSArray* json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    
    for (NSDictionary *object in json) {
        float lat = [[object objectForKey:@"lat"] floatValue];
        float lon = [[object objectForKey:@"lon"] floatValue];
        NSString *name = [NSString stringWithFormat:@"%@", [object objectForKey:@"name"]];
        
        CLLocationCoordinate2D position = CLLocationCoordinate2DMake(lat, lon);
        GMSMarker *marker = [GMSMarker markerWithPosition:position];
        marker.title = name;
        marker.icon = [UIImage imageNamed:@"bus_stop"];
        marker.map = mapView_;
    }
}

-(void)updateBusData:(int)routeID
{
    dispatch_async(kBgQueue, ^{
        NSData* data = [NSData dataWithContentsOfURL: [NSURL URLWithString: [NSString stringWithFormat:@"http://beta.ctthosting.com/sbu/list_buses/?id=%d", routeID]]];
        [self performSelectorOnMainThread:@selector(updateBusLocations:) withObject:data waitUntilDone:YES];
    });
}

-(void)updateBusLocations:(NSData*)routeData {
    
    NSString *strData = [[NSString alloc]initWithData:routeData encoding:NSUTF8StringEncoding];
    NSData *data = [strData dataUsingEncoding:NSUTF8StringEncoding];
    NSError* error;
    NSArray* json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    
    for (NSDictionary *object in json) {
        float lat = [[object objectForKey:@"lat"] floatValue];
        float lon = [[object objectForKey:@"lon"] floatValue];
        NSString *name = [NSString stringWithFormat:@"%@", [object objectForKey:@"name"]];
        
        CLLocationCoordinate2D position = CLLocationCoordinate2DMake(lat, lon);
        GMSMarker *marker = [GMSMarker markerWithPosition:position];
        marker.title = name;
        marker.icon = [UIImage imageNamed:@"sb_bus"];
        marker.map = mapView_;
        
        [busMarkers addObject:marker];
    }
}

//_________________________________________________________________________________________________
//_________________________________________________________________________________________________
//_________________________________________________________________________________________________


// Assumes input like "#00FF00" (#RRGGBB).
- (UIColor *)colorFromHexString:(NSString *)hexString {
    unsigned rgbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:hexString];
    [scanner setScanLocation:1]; // bypass '#' character
    [scanner scanHexInt:&rgbValue];
    return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:1.0];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
