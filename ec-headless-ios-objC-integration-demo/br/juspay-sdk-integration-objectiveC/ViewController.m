//
//  ViewController.m
//  juspay-sdk-integration-objc
//

#import "ViewController.h"

@interface ViewController ()

// Create an instance of GlobalJuspayPaymentsServices
// block:start:create-global-juspay-payments-services-instance
@property (nonatomic, strong) GlobalJuspayPaymentsServices *globalJuspayInstance;
// block:end:create-global-juspay-payments-services-instance

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Initialize GlobalJuspayPaymentsServices
    self.globalJuspayInstance = [[GlobalJuspayPaymentsServices alloc] init];
}

// Creating initiate payload JSON object
// block:start:create-initiate-payload
- (NSDictionary *)createInitiatePayload {
    NSDictionary *innerPayload = @{
        @"action": @"initiate",
        @"merchantId": @"<MERCHANT_ID>",
        @"clientId": @"<CLIENT_ID>",
        @"customerId": @"<CUSTOMER_ID>",
        @"environment": @"prod"
    };
    
    NSDictionary *sdkPayload = @{
        @"requestId": [[NSUUID UUID] UUIDString],
        @"service": @"hyperapi",
        @"payload": innerPayload
    };
    
    return sdkPayload;
}
// block:end:create-initiate-payload

// Creating GlobalJuspayPaymentsCallback
// This callback will get all events from globalJuspay Instance
// block:start:create-hyper-callback
- (GlobalJuspayPaymentsCallback)globalJuspayCallbackHandler {
    __weak typeof(self) weakSelf = self;
    return ^(NSDictionary *response) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        
        if (response != nil && [response[@"event"] isKindOfClass:[NSString class]]) {
            NSString *event = response[@"event"];
            
            if ([event isEqualToString:@"hide_loader"]) {
                // hide loader
            }
            // Handle Process Result
            else if ([event isEqualToString:@"process_result"]) {
                BOOL error = [response[@"error"] boolValue];
                NSDictionary *innerPayload = response[@"payload"];
                NSString *status = innerPayload[@"status"];
                NSString *pi = innerPayload[@"paymentInstrument"];
                NSString *pig = innerPayload[@"paymentInstrumentGroup"];
                
                if (!error) {
                    // txn success, status should be "charged"
                    // process data -- show pi and pig in UI maybe also?
                    // example -- pi: "PAYTM", pig: "WALLET"
                    // call orderStatus once to verify (false positives)
                } else {
                    NSString *errorCode = response[@"errorCode"];
                    NSString *errorMessage = response[@"errorMessage"];
                    
                    if ([status isEqualToString:@"backpressed"]) {
                        // user back-pressed from checkout screen without initiating any txn
                    } else if ([status isEqualToString:@"user_aborted"]) {
                        // user initiated a txn and pressed back
                        // poll order status
                    } else if ([status isEqualToString:@"pending_vbv"] || [status isEqualToString:@"authorizing"]) {
                        // txn in pending state
                        // poll order status until backend says fail or success
                    } else if ([status isEqualToString:@"authorization_failed"] || 
                               [status isEqualToString:@"authentication_failed"] || 
                               [status isEqualToString:@"api_failure"]) {
                        // txn failed
                        // poll orderStatus to verify (false negatives)
                    } else if ([status isEqualToString:@"new"]) {
                        // order created but txn failed
                        // also failure
                        // poll order status
                    } else {
                        // unknown status, this is also failure
                        // poll order status
                    }
                }
            }
        }
    };
}
// block:end:create-hyper-callback

// Initiating payments when button is clicked
- (IBAction)initiatePayments:(id)sender {
    // Calling initiate on hyperService instance to boot up payment engine.
    // block:start:initiate-sdk
    [self.globalJuspayInstance initiate:self
                                payload:[self createInitiatePayload]
                               callback:[self globalJuspayCallbackHandler]];
    // block:end:initiate-sdk
}

// Creating process payload JSON object
// block:start:process-sdk-call
- (void)processPaymentWithPayload:(NSDictionary *)processPayload {
    if ([self.globalJuspayInstance isInitialised]) {
        [self.globalJuspayInstance process:processPayload];
    }
}
// block:end:process-sdk-call

@end
