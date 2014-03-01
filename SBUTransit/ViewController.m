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
    NSMutableArray *currentServiceRoutesMenu;
    NSArray *currentServiceRoutes;
    NSTimer *busUpdates;
    MBHUDView *alert;
    JCGridMenuRow *share;
    
}

#define GM_TAG        1002
@synthesize gmDemo = _gmDemo;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    alert = [MBHUDView hudWithBody:@"Loading" type:MBAlertViewHUDTypeActivityIndicator hidesAfter:99999.0 show:NO];
    
    [self showLoading];
	// Do any additional setup after loading the view, typically from a nib.
    
    currentServiceRoutesMenu = [[NSMutableArray alloc] init];
    busMarkers = [[NSMutableArray alloc] init];
    
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:40.9156161
                                                            longitude:-73.1239215
                                                                 zoom:14];
    mapView_ = [GMSMapView mapWithFrame:[[UIScreen mainScreen] bounds] camera:camera];
    mapView_.myLocationEnabled = YES;
    [mapViewOnScreen addSubview:mapView_];

    self.view = mapViewOnScreen;
    
    
    int routeNumber = 3;
    

    dispatch_async(kBgQueue, ^{
        [self showLoading];
       // NSData* data = [NSData dataWithContentsOfURL: [NSURL URLWithString: [NSString stringWithFormat:@"http://h.cttapp.com/sbu/route_info/?id=%d", routeNumber]]];
       // [self performSelectorOnMainThread:@selector(setRouteOnMap:) withObject:data waitUntilDone:YES];
        
         NSData* data = [NSData dataWithContentsOfURL: [NSURL URLWithString: @"http://h.cttapp.com/sbu/get_service/"]];
         [self performSelectorOnMainThread:@selector(getService:) withObject:data waitUntilDone:YES];
        
        NSData* data2 = [NSData dataWithContentsOfURL: [NSURL URLWithString: @"http://h.cttapp.com/sbu/get_announcements/"]];
        [self performSelectorOnMainThread:@selector(getAnnouncements:) withObject:data2 waitUntilDone:YES];

    });
     

    

    
    
    
}

-(void)getAnnouncements:(NSData*)serviceData
{
    NSString *strData = [[NSString alloc]initWithData:serviceData encoding:NSUTF8StringEncoding];
    NSData *data = [strData dataUsingEncoding:NSUTF8StringEncoding];
    NSError* error;
    NSArray* json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    
    NSLog(@"Announcements (%d):\n%@",[json count], json);
    if ([json count] > 0)
    {
        MBAlertView *alert = [MBAlertView alertWithBody:[NSString stringWithFormat:@"%@", json] cancelTitle:@"Okay" cancelBlock:nil];
        [alert addToDisplayQueue];
    }
    
}

-(void)getService:(NSData*)serviceData
{
    NSString *strData = [[NSString alloc]initWithData:serviceData encoding:NSUTF8StringEncoding];
    NSData *data = [strData dataUsingEncoding:NSUTF8StringEncoding];
    NSError* error;
    NSArray* json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    NSDictionary* routeInfo = [json objectAtIndex:0];
    NSString *serviceLevel = [routeInfo objectForKey:@"servicelevel"];
    NSLog(@"Loading service for level %@", serviceLevel);
    dispatch_async(kBgQueue, ^{
         NSData* data = [NSData dataWithContentsOfURL: [NSURL URLWithString: [NSString stringWithFormat:@"http://h.cttapp.com/sbu/get_routes/?id=%@", serviceLevel]]];
         [self performSelectorOnMainThread:@selector(loadMenu:) withObject:data waitUntilDone:YES];
    });
}

-(void)loadMenu:(NSData*)routeData
{
    
    NSString *strData = [[NSString alloc]initWithData:routeData encoding:NSUTF8StringEncoding];
    NSData *data = [strData dataUsingEncoding:NSUTF8StringEncoding];
    NSError* error;
    NSArray* json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    currentServiceRoutes = json;
    
    NSLog(@"Found %d runs: \n%@", [json count], json);
    
    
    for (int i = 0; i < [json count]; i++) {
        
        NSDictionary *tempDict = [json objectAtIndex:i];
        
        JCGridMenuColumn *tempMenu = [[JCGridMenuColumn alloc]
                                     initWithButtonAndImages:CGRectMake(0, 0, 44, 44)
                                     normal:[tempDict objectForKey:@"image"]
                                     selected:[tempDict objectForKey:@"image"]
                                     highlighted:[tempDict objectForKey:@"image"]
                                     disabled:[tempDict objectForKey:@"image"]];
        [tempMenu.button setBackgroundColor:[UIColor colorWithWhite:0.0f alpha:0.8f]];
        [tempMenu setCloseOnSelect:YES];
        
        [currentServiceRoutesMenu addObject:tempMenu];
        
    }
    NSLog(@"Items in menu array\n%@", currentServiceRoutesMenu);
    
    NSDictionary *tempDict2 = [json objectAtIndex:0];
    
    share = [[JCGridMenuRow alloc] initWithImages:[tempDict2 objectForKey:@"image"] selected:@"CloseSelected" highlighted:[tempDict2 objectForKey:@"image"] disabled:[tempDict2 objectForKey:@"image"]];
    [share setColumns:currentServiceRoutesMenu];
    
    [share setIsModal:YES];
    [share setHideAlpha:0.2f];
    [share setIsSeperated:YES];
    [share.button setBackgroundColor:[UIColor colorWithWhite:0.0f alpha:0.4f]];
    
    // Rows...
    
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    //CGFloat screenWidth = screenRect.size.width;
    CGFloat screenHeight = screenRect.size.height;
    
    NSArray *rows = [[NSArray alloc] initWithObjects: share, nil];
    _gmDemo = [[JCGridMenuController alloc] initWithFrame:CGRectMake(0,screenHeight-44,320,(44*[rows count])+[rows count]) rows:rows tag:GM_TAG];
    [_gmDemo setDelegate:self];
    [self.view addSubview:_gmDemo.view];
    
    dispatch_async(kBgQueue, ^{
        NSData* data = [NSData dataWithContentsOfURL: [NSURL URLWithString: [NSString stringWithFormat:@"http://h.cttapp.com/sbu/route_info/?id=%@", [tempDict2 objectForKey:@"id"]]]];
        [self performSelectorOnMainThread:@selector(setRouteOnMap:) withObject:data waitUntilDone:YES];
    });
    
    [_gmDemo open];

}

-(void)setRouteOnMap:(NSData*)routeData {
    
    [mapView_ clear];
    [busUpdates invalidate];
    
    float highLat = -200;
    float highLon = -200;
    float lowLat = 200;
    float lowLon = 200;
    
    
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
        if(lat > highLat)
            highLat = lat;
        if(lon > highLon)
            highLon = lon;
        if(lat < lowLat)
            lowLat = lat;
        if(lon < lowLon)
            lowLon = lon;
    }

    
    polyline.path = path;
    polyline.strokeColor = [self colorFromHexString:[NSString stringWithFormat:@"%@", [routeInfo objectForKey:@"color"]]];
    polyline.strokeWidth = 3.f;
    polyline.map = mapView_;
    
    float camLat = (highLat + lowLat) / 2;
    float camLon = (highLon + lowLon) / 2;
    

    
    
    
    
    GMSCoordinateBounds *newBounds = [[GMSCoordinateBounds alloc] initWithPath:path];
    GMSCameraUpdate *update = [GMSCameraUpdate fitBounds:newBounds];
    [mapView_ animateWithCameraUpdate:update];
    
    NSLog(@"Map location: %.5f, %.5f", camLat, camLon);
    
    dispatch_async(kBgQueue, ^{
        NSData* data = [NSData dataWithContentsOfURL: [NSURL URLWithString: [NSString stringWithFormat:@"http://h.cttapp.com/sbu/get_stops_by_id/?id=%d", routeIDNumber]]];
        [self performSelectorOnMainThread:@selector(setStopsOnMap:) withObject:data waitUntilDone:YES];
    });
    dispatch_async(kBgQueue, ^{
        [self updateBusData:[NSString stringWithFormat:@"%d", routeIDNumber]];
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
        marker.icon = [UIImage imageNamed:@"light-gray-point"];
        marker.map = mapView_;
    }
    
    [self hideLoading];
    [alert dismiss];
    NSLog(@"Should have stopped loading");
}

-(void)updateBusData:(NSString*)routeID
{
    dispatch_async(kBgQueue, ^{
        NSData* data = [NSData dataWithContentsOfURL: [NSURL URLWithString: [NSString stringWithFormat:@"http://h.cttapp.com/sbu/list_buses/?id=%@", routeID]]];
        [self performSelectorOnMainThread:@selector(updateBusLocations:) withObject:data waitUntilDone:YES];
    });
    
    dispatch_async(dispatch_get_main_queue(), ^{
    
            busUpdates = [NSTimer scheduledTimerWithTimeInterval:2.0
                                             target:self
                                           selector:@selector(handleTimer:)
                                           userInfo:[NSString stringWithFormat:@"%@", routeID] repeats:NO];
    });
    
    NSLog(@"Loading data for route %@", routeID);

}

- (void)handleTimer:(NSTimer*)theTimer {
    [self updateBusData:[theTimer userInfo]];
    NSLog(@"Running timer");
}

-(void)updateBusLocations:(NSData*)routeData {
    
    NSString *strData = [[NSString alloc]initWithData:routeData encoding:NSUTF8StringEncoding];
    NSData *data = [strData dataUsingEncoding:NSUTF8StringEncoding];
    NSError* error;
    NSArray* json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    
    NSLog(@"Updateing bus count: \nBus Markers: %d\nJSON Count: %d\nBus Data: \nJSON Data: ", [busMarkers count], [json count]);
    
    //Case 1
    if(([busMarkers count] != [json count])&& [busMarkers count] > 0)
    {
        NSLog(@"Case 1");
        for(GMSMarker *busMarker in busMarkers)
        {
            busMarker.map = nil;
        }
    }
    //Case 2
    else if([busMarkers count] > 0 && ([busMarkers count] == [json count]))
    {
        NSLog(@"Case 2");
        for(int x = 0; x < [json count]; x++)
        {
            NSDictionary *object = [json objectAtIndex:x];
            float lat = [[object objectForKey:@"lat"] floatValue];
            float lon = [[object objectForKey:@"lon"] floatValue];
            NSString *name = [NSString stringWithFormat:@"%@", [object objectForKey:@"name"]];
            CLLocationCoordinate2D position = CLLocationCoordinate2DMake(lat, lon);
            
            GMSMarker *currentMarker = [busMarkers objectAtIndex:x];
            currentMarker.position = position;
            currentMarker.title = name;
            currentMarker.snippet = [NSString stringWithFormat:@"%@ | Bus #%d",[object objectForKey:@"driver_name"], [[object objectForKey:@"busNum"] intValue] ];
            currentMarker.icon = [UIImage imageNamed:@"red-point"];
//            marker.map = mapView_;

        }
    }
    //Case 3
    else
    {
        NSLog(@"Case 3");
        for (NSDictionary *object in json) {
            float lat = [[object objectForKey:@"lat"] floatValue];
            float lon = [[object objectForKey:@"lon"] floatValue];
            NSString *name = [NSString stringWithFormat:@"%@", [object objectForKey:@"name"]];
        
            CLLocationCoordinate2D position = CLLocationCoordinate2DMake(lat, lon);
            GMSMarker *marker = [GMSMarker markerWithPosition:position];
            marker.title = name;
            marker.snippet = [NSString stringWithFormat:@"%@ | Bus #%d",[object objectForKey:@"driver_name"], [[object objectForKey:@"busNum"] intValue] ];
            marker.icon = [UIImage imageNamed:@"red-point"];
            marker.map = mapView_;
        
            [busMarkers addObject:marker];
            NSLog(@"New BusMarkers count: %d\nData: %@", [busMarkers count], busMarkers);
        }
    }
    
    if (!json || !json.count)
    {
        NSLog(@"There are no buses operating at this time");
        //[METoast resetToastAttribute];
        //[METoast toastWithMessage:@"There are no buses operating at this time."];
        
    }
}

//_________________________________________________________________________________________________
//_________________________________________________________________________________________________
//_________________________________________________________________________________________________


#pragma mark - JCGridMenuController Delegate

- (void)jcGridMenuRowSelected:(NSInteger)indexTag indexRow:(NSInteger)indexRow isExpand:(BOOL)isExpand
{
    if (isExpand) {
        NSLog(@"jcGridMenuRowSelected %i %i isExpand", indexTag, indexRow);
    } else {
        NSLog(@"jcGridMenuRowSelected %i %i !isExpand", indexTag, indexRow);
    }
    
    if (indexTag==GM_TAG) {
        JCGridMenuRow *rowSelected = (JCGridMenuRow *)[_gmDemo.rows objectAtIndex:indexRow];
        
        if (indexRow==0) {
            // Search
            [[rowSelected button] setSelected:YES];
        }
        
    }
    
}

- (void)jcGridMenuColumnSelected:(NSInteger)indexTag indexRow:(NSInteger)indexRow indexColumn:(NSInteger)indexColumn
{
    NSLog(@"jcGridMenuColumnSelected %i %i %i", indexTag, indexRow, indexColumn);
    
    if (indexTag==GM_TAG) {
        
        if (indexRow==0) {
            // Search
            [[[_gmDemo.gridCells objectAtIndex:indexRow] button] setSelected:NO];
        }
        
        [_gmDemo setIsRowModal:NO];
        
        NSString *routeNumber = [[currentServiceRoutes objectAtIndex:indexColumn] objectForKey:@"id"];
        NSString *routeName = [[currentServiceRoutes objectAtIndex:indexColumn] objectForKey:@"name"];
        NSString *routeImage = [[currentServiceRoutes objectAtIndex:indexColumn] objectForKey:@"image"];
        NSLog(@"Loading route %@ (%@)", routeNumber, routeName);
        
        [[[_gmDemo.gridCells objectAtIndex:indexRow] button] setImage:[UIImage imageNamed:routeImage] forState:UIControlStateNormal];
        
        
        [self showLoading];
        dispatch_async(kBgQueue, ^{
            //busMarkers = [[NSMutableArray alloc] init];
            [busMarkers removeAllObjects];
            
             NSData* data = [NSData dataWithContentsOfURL: [NSURL URLWithString: [NSString stringWithFormat:@"http://h.cttapp.com/sbu/route_info/?id=%@", routeNumber]]];
             [self performSelectorOnMainThread:@selector(setRouteOnMap:) withObject:data waitUntilDone:YES];
        });
        
    }
    
}


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

-(void)showLoading {
    
    alert = [MBHUDView hudWithBody:@"Loading" type:MBAlertViewHUDTypeActivityIndicator hidesAfter:99999.0 show:YES];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [alert show];
    });
}

-(void)hideLoading {
    [alert dismiss];
    dispatch_async(dispatch_get_main_queue(), ^{
        [alert dismiss];
    });
}

@end
