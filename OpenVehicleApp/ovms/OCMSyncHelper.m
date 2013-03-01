//
//  OpenChargeSync.m
//  OpenChargeMap
//
//  Created by JLab13 on 2/20/13.
//  Copyright (c) 2013 JLab13. All rights reserved.
//

#import "OCMSyncHelper.h"
#import "ovmsAppDelegate.h"
#import "NSObject+CDHelper.h"

#import "EntityName.h"

#define NULL_TO_NIL(obj) ({ __typeof__ (obj) __obj = (obj); __obj == [NSNull null] ? nil : obj; })
#define BASE_URL @"http://www.openchargemap.org/api/?output=json"
#define SWF(format, args...) [NSString stringWithFormat:format, args]

@interface OCMSyncHelper()
@property (nonatomic, strong) id<OCMSyncDelegate> delegate;
@property (nonatomic, assign) BOOL isProcess;
@end

@implementation OCMSyncHelper

- (id)initWithDelegate:(id)delegate {
    if ([super init]) {
        self.delegate = delegate;
        self.isProcess = NO;
    }
    return self;
}

- (void)startSyncWhithCoordinate:(CLLocationCoordinate2D)coordinate toDistance:(double)distance {
    if (self.isProcess) return;
    
    self.isProcess = YES;
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    NSString *surl = SWF(@"%@&latitude=%0.6f&longitude=%0.6f&distance=%g&distanceunit=KM", BASE_URL,
                         coordinate.latitude, coordinate.longitude, distance);
    
    NSLog(@"start sync: %@", surl);
    
    [self performSelectorInBackground:@selector(start:) withObject:[NSURL URLWithString:surl]];
}

- (void)start:(NSURL *)url {
    NSError* error = nil;
    NSData *receivedData = [NSData dataWithContentsOfURL:url options:NSDataReadingUncached error:&error];
    
    if (error) {
        [self performSelectorOnMainThread:@selector(stop:) withObject:error waitUntilDone:NO];
        return;
    }
    
    NSArray* json = [NSJSONSerialization JSONObjectWithData:receivedData
                                                    options:kNilOptions
                                                      error:&error];
    if (error) {
        [self performSelectorOnMainThread:@selector(stop:) withObject:error waitUntilDone:NO];
        return;
    }
    
    if (json.count) {
//        [self parseData:json];
        [self performSelectorOnMainThread:@selector(parseAndStop:) withObject:json waitUntilDone:NO];
    } else {
        NSLog(@"Response empty data");
        [self performSelectorOnMainThread:@selector(stop:) withObject:nil waitUntilDone:NO];
    }
}

- (void)parseAndStop:(NSArray *)items {
    [self parseData:items];
    [self stop:nil];
}

- (void)stop:(NSError *)error {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    
    if (error) {
        NSLog(@"ERROR %@, %@", error, [error userInfo]);
        
        if ([self.delegate respondsToSelector:@selector(didFailWithError:)]) {
            [self.delegate didFailWithError:error];
        }
        return;
    }
    
    if ([self.delegate respondsToSelector:@selector(didFinishSync)]) {
        [self.delegate didFinishSync];
    }
    self.isProcess = NO;
}

#pragma mark - parse data
- (void)parseData:(NSArray *)items {
    for (NSDictionary *row in items) {
        [self parseChargingLocations:row];
    }
    [[ovmsAppDelegate myRef] saveContext];
    
    NSLog(@"Sync %d records.", items.count);
}

- (void)parseChargingLocations:(NSDictionary *)row {
    ChargingLocation *cl = [self entityWithName:ENChargingLocation asWhere:@"uuid" inValue:row[@"UUID"]];
    if (!cl) {
        cl = [NSEntityDescription insertNewObjectForEntityForName:ENChargingLocation
                                                                inManagedObjectContext:self.managedObjectContext];
    }
    
    cl.uuid = NULL_TO_NIL(row[@"UUID"]);
    cl.usage_cost = NULL_TO_NIL(row[@"UsageCost"]);
    cl.data_providers_reference = NULL_TO_NIL(row[@"DataProvidersReference"]);
    cl.data_quality_level = NULL_TO_NIL(row[@"DataQualityLevel"]);
    cl.general_comments = NULL_TO_NIL(row[@"GeneralComments"]);
    cl.number_of_points = NULL_TO_NIL(row[@"NumberOfPoints"]);
    if (NULL_TO_NIL(row[@"StatusType"])) {
        cl.status_is_operational = NULL_TO_NIL(row[@"StatusType"][@"IsOperational"]);
        cl.status_title = NULL_TO_NIL(row[@"StatusType"][@"Title"]);
    }
    
    [self parseAddressInfoToChargingLocations:cl asObject:NULL_TO_NIL(row[@"AddressInfo"])];
    [self parseOperatorInfoToChargingLocations:cl asObject:NULL_TO_NIL(row[@"OperatorInfo"])];
//    [self parseChargerToChargingLocations:cl asArray:NULL_TO_NIL(row[@"Chargers"])];
    [self parseConnectionToChargingLocations:cl asArray:NULL_TO_NIL(row[@"Connections"])];
}

- (void)parseAddressInfoToChargingLocations:(ChargingLocation *)cl asObject:(NSDictionary *)row {
    if (!row) {
        cl.addres_info = nil;
        return;
    }
    
    AddressInfo *ai = cl.addres_info;
    if (!ai || ![ai.id isEqualToNumber:row[@"ID"]]) {
        ai = [NSEntityDescription insertNewObjectForEntityForName:ENAddressInfo
                                               inManagedObjectContext:self.managedObjectContext];
        cl.addres_info = ai;
    }
    ai.id = row[@"ID"];
    ai.access_comments = NULL_TO_NIL(row[@"AccessComments"]);
    ai.address_line1 = NULL_TO_NIL(row[@"AddressLine1"]);
    ai.contact_telephone1 = NULL_TO_NIL(row[@"ContactTelephone1"]);
    ai.country_iso_code = NULL_TO_NIL(row[@"Country"][@"ISOCode"]);
    ai.country_title = NULL_TO_NIL(row[@"Country"][@"Title"]);
    ai.latitude = NULL_TO_NIL(row[@"Latitude"]);
    ai.longitude = NULL_TO_NIL(row[@"Longitude"]);
    ai.postcode = NULL_TO_NIL(row[@"Postcode"]);
    ai.related_url = NULL_TO_NIL(row[@"RelatedURL"]);
    ai.state_or_province = NULL_TO_NIL(row[@"StateOrProvince"]);
    ai.title = NULL_TO_NIL(row[@"Title"]);
    ai.town = NULL_TO_NIL(row[@"Town"]);
}

- (void)parseOperatorInfoToChargingLocations:(ChargingLocation *)cl asObject:(NSDictionary *)row {
    if (!row) {
        cl.operator_info = nil;
        return;
    }
    
    OperatorInfo *oi = cl.operator_info;
    if (!oi || ![oi.id isEqualToNumber:row[@"ID"]]) {
        oi = [NSEntityDescription insertNewObjectForEntityForName:ENOperatorInfo
                                           inManagedObjectContext:self.managedObjectContext];
        cl.operator_info = oi;
    }
    oi.id = row[@"ID"];
    oi.address_info = NULL_TO_NIL(row[@"AddressInfo"]);
    oi.booking_url = NULL_TO_NIL(row[@"BookingURL"]);
    oi.comments = NULL_TO_NIL(row[@"Comments"]);
    oi.contact_email = NULL_TO_NIL(row[@"ContactEmail"]);
    oi.fault_report_email = NULL_TO_NIL(row[@"FaultReportEmail"]);
    oi.is_private_individual = NULL_TO_NIL(row[@"IsPrivateIndividual"]);
    oi.phone_primary_contact = NULL_TO_NIL(row[@"PhonePrimaryContact"]);
    oi.phone_secondary_contact = NULL_TO_NIL(row[@"PhoneSecondaryContact"]);
    oi.title = NULL_TO_NIL(row[@"Title"]);
    oi.website_url = NULL_TO_NIL(row[@"WebsiteURL"]);
}

- (void)parseConnectionToChargingLocations:(ChargingLocation *)cl asArray:(NSArray *)items {
    if (!items) {
        [cl setValue:nil forKey:@"conections"];
        cl.conections = nil;
        return;
    }
    
    NSSet *conections = [NSSet setWithSet:cl.conections];
    for (Connection *co in conections) {
        [cl removeConectionsObject:co];
    }
    
    for (NSDictionary *row in items) {
        Connection *co = [self entityWithName:ENConnection asWhere:@"id" inValue:row[@"ID"]];
        if (!co) {
            co = [NSEntityDescription insertNewObjectForEntityForName:ENConnection
                                                   inManagedObjectContext:self.managedObjectContext];
        }
        
        co.id = row[@"ID"];
        co.amps = NULL_TO_NIL(row[@"Amps"]);
        co.comments = NULL_TO_NIL(row[@"Comments"]);
        co.voltage = NULL_TO_NIL(row[@"Voltage"]);
        co.power_kw = NULL_TO_NIL(row[@"PowerKW"]) ;
        co.quantity = NULL_TO_NIL(row[@"Quantity"]);
        co.reference = NULL_TO_NIL(row[@"Reference"]);
        if (NULL_TO_NIL(row[@"Level"])) {
            co.level_comments = NULL_TO_NIL(row[@"Level"][@"Comments"]);
            co.level_is_fast_charge = NULL_TO_NIL(row[@"Level"][@"IsFastChargeCapable"]);
            co.level_title = NULL_TO_NIL(row[@"Level"][@"Title"]);
        }
        if (NULL_TO_NIL(row[@"StatusType"])) {
            co.status_is_operational = NULL_TO_NIL(row[@"StatusType"][@"IsOperational"]);
            co.status_title = NULL_TO_NIL(row[@"StatusType"][@"Title"]);
        }
        if (NULL_TO_NIL(row[@"ConnectionType"])) {
            co.type_formal_name = NULL_TO_NIL(row[@"ConnectionType"][@"FormalName"]);
            co.type_is_discontinued = NULL_TO_NIL(row[@"ConnectionType"][@"IsDiscontinued"]);
            co.type_is_obsolete = NULL_TO_NIL(row[@"ConnectionType"][@"IsObsolete"]);
            co.type_title = NULL_TO_NIL(row[@"ConnectionType"][@"Title"]);
        }
        
        [cl addConectionsObject:co];
    }
}

@end
