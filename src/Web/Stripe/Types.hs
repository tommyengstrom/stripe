{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards   #-}

module Web.Stripe.Types where

import           Control.Applicative
import           Control.Monad
import           Data.Aeson
import           Data.Text                  (Text)
import           Data.Time                  (UTCTime)
import           Data.Vector

import           Web.Stripe.Client.Internal

newtype ChargeId = ChargeId Text deriving (Show, Eq)

type Key = Text
type Value = Text

data Charge = Charge {
      chargeId                   :: Text
    , chargeObject               :: Text
    , chargeCreated              :: UTCTime
    , chargeLiveMode             :: Bool
    , chargePaid                 :: Bool
    , chargeAmount               :: Int
    , chargeCurrency             :: Currency
    , chargeRefunded             :: Bool
    , chargeCreditCard           :: Card
    , chargeCaptured             :: Bool
    , chargeRefunds              :: StripeList Refund
    , chargeBalanceTransaction   :: TransactionId
    , chargeFailureMessage       :: Maybe Text
    , chargeFailureCode          :: Maybe Text
    , chargeAmountRefunded       :: Int
    , chargeCustomerId           :: Maybe CustomerId
    , chargeInvoice              :: Maybe InvoiceId
    , chargeDescription          :: Maybe Text
    , chargeDispute              :: Maybe Text
    , chargeStatementDescription :: Maybe Text
    , chargeReceiptEmail         :: Maybe Text
    } deriving Show

newtype StatementDescription = StatementDescription Text deriving (Show, Eq)
type Capture = Bool

newtype ReceiptEmail = ReceiptEmail Text deriving (Show, Eq)

data StripeList a = StripeList {
      list       :: [a]
    , url        :: Text
    , object     :: Text
    , totalCount :: Maybe Int
    , hasMore    :: Bool
    } deriving (Show, Eq)

instance FromJSON a => FromJSON (StripeList a) where
    parseJSON (Object o) =
        StripeList <$> o .:  "data"
                   <*> o .:  "url"
                   <*> o .:  "object"
                   <*> o .:? "total_count"
                   <*> o .:  "has_more"

instance FromJSON Charge where
    parseJSON (Object o) =
        Charge <$> o .: "id"
               <*> o .: "object"
               <*> (fromSeconds <$> o .: "created")
               <*> o .: "livemode"
               <*> o .: "paid"
               <*> o .: "amount"
               <*> (Currency <$> o .: "currency")
               <*> o .: "refunded"
               <*> o .: "card"
               <*> o .: "captured"
               <*> o .: "refunds"
               <*> (TransactionId <$> o .: "balance_transaction")
               <*> o .:? "failure_message"
               <*> o .:? "failure_code"
               <*> o .: "amount_refunded"
               <*> (fmap CustomerId <$> o .:? "customer")
               <*> (fmap InvoiceId <$> o .:? "invoice")
               <*> o .:? "description"
               <*> o .:? "dispute"
               <*> o .:? "statement_description"
               <*> o .:? "receipt_email"

--- Refund ---
data Refund = Refund {
      refundId                 :: Text
    , refundAmount             :: Int
    , refundCurrency           :: Text
    , refundCreated            :: UTCTime
    , refundObject             :: Text
    , refundCharge             :: ChargeId
    , refundBalanceTransaction :: TransactionId
--    , refundMetaData           :: [(Text,Text)]
    } deriving (Show, Eq)

instance FromJSON Refund where
   parseJSON (Object o) =
        Refund <$> o .: "id"
               <*> o .: "amount"
               <*> o .: "currency"
               <*> (fromSeconds <$> o .: "created")
               <*> o .: "object"
               <*> (ChargeId <$> o .: "charge")
               <*> (TransactionId <$> o .: "balance_transaction")
--               <*> o .: "metadata"

newtype RefundId = RefundId Text deriving (Show)

-- Customer --
newtype CustomerId = CustomerId Text deriving (Show,Eq)

data Customer = Customer {
      customerObject         :: Text
    , customerCreated        :: UTCTime
    , customerId             :: CustomerId
    , customerLiveMode       :: Bool
    , customerDescription    :: Maybe Text
    , customerEmail          :: Maybe Text
    , customerDelinquent     :: Bool
    , customerSubscriptions  :: StripeList Subscription
    , customerDiscount       :: Maybe Text
    , customerAccountBalance :: Int
    , customerCurrency       :: Maybe Currency
    , customerDefaultCard    :: Maybe CardId
    } deriving (Show, Eq)

instance FromJSON Customer where
    parseJSON (Object o)
        = Customer
           <$> o .: "object"
           <*> (fromSeconds <$> o .: "created")
           <*> (CustomerId <$> o .: "id")
           <*> o .: "livemode"
           <*> o .:? "description"
           <*> o .:? "email"
           <*> o .: "delinquent"
           <*> o .: "subscriptions"
           <*> o .:? "discount"
           <*> o .: "account_balance"
           <*> (fmap Currency <$> o .:? "currency")
           <*> (fmap CardId <$> o .:? "default_card")

---- ==== Card ==== -----
newtype CardId         = CardId Text deriving (Show, Eq)
newtype CardNumber     = CardNumber Int deriving (Show, Eq, Ord)
newtype ExpMonth       = ExpMonth Int deriving (Show, Eq, Ord)
newtype ExpYear        = ExpYear Int deriving (Show, Eq, Ord)
newtype CVC            = CVC Int deriving (Show, Eq, Ord)
newtype AddressCity    = AddressCity Text deriving (Show, Eq)
newtype AddressCountry = AddressCountry Text deriving (Show, Eq)
newtype AddressLine1   = AddressLine1 Text deriving (Show, Eq)
newtype AddressLine2   = AddressLine2 Text deriving (Show, Eq)
newtype AddressState   = AddressState Text deriving (Show, Eq)
newtype AddressZip     = AddressZip Text deriving (Show, Eq)
newtype EndingBefore   = EndingBefore Text deriving (Show, Eq)
newtype StartingAfter  = StartingAfter Text deriving (Show, Eq)
newtype Limit          = Limit Int deriving (Show, Eq)

data Brand = Visa
           | AMEX
           | MasterCard
           | Discover
           | JCB
           | DinersClub
           | Unknown
             deriving (Show, Eq)

data Card = Card {
      cardId                  :: Text
    , cardLastFour            :: Text
    , cardBrand               :: Brand
    , cardFunding             :: Text
    , cardExpMonth            :: Int
    , cardExpYear             :: Int
    , cardFingerprint         :: Text
    , cardCountry             :: Text
    , cardName                :: Maybe Text
    , cardAddress_line1       :: Maybe Text
    , cardAddress_line2       :: Maybe Text
    , cardAddress_city        :: Maybe Text
    , cardAddress_state       :: Maybe Text
    , cardAddress_zip         :: Maybe Text
    , cardAddress_country     :: Maybe Text
    , cardCvc_check           :: Maybe Text
    , cardAddress_line1_check :: Maybe Text
    , cardAddress_zip_check   :: Maybe Text
    , cardCustomer            :: Maybe Text
} deriving (Show, Eq)

instance FromJSON Brand where
    parseJSON (String result) =
        return $ case result of
                   "American Express" -> AMEX
                   "MasterCard" -> MasterCard
                   "Discover" -> Discover
                   "JCB" -> JCB
                   "Visa" -> Visa
                   "DinersClub" -> DinersClub
                   otherwise -> Unknown

instance FromJSON Card where
    parseJSON (Object o) =
        Card <$> o .: "id"
             <*> o .: "last4"
             <*> o .: "brand"
             <*> o .: "funding"
             <*> o .: "exp_month"
             <*> o .: "exp_year"
             <*> o .: "fingerprint"
             <*> o .: "country"
             <*> o .:? "name"
             <*> o .:? "address_line1"
             <*> o .:? "address_line2"
             <*> o .:? "address_city"
             <*> o .:? "address_state"
             <*> o .:? "address_zip"
             <*> o .:? "address_country"
             <*> o .:? "cvc_check"
             <*> o .:? "address_line1_check"
             <*> o .:? "address_zip_check"
             <*> o .:? "customer"

-- Token --
newtype TokenId = TokenId Text deriving (Show, Eq, Ord)

data TokenType = TokenCard | TokenBankAccount deriving (Show, Eq)

instance FromJSON TokenType where
   parseJSON (String "bank_account") = pure TokenBankAccount
   parseJSON (String "card") = pure TokenCard
   parseJSON _ = mzero

data Token = Token {
      tokenId       :: TokenId
    , tokenLiveMode :: Bool
    , tokenCreated  :: UTCTime
    , tokenUsed     :: Bool
    , tokenObject   :: Text
    , tokenType     :: TokenType
    , tokenCard     :: Card
} deriving (Show)

instance FromJSON Token where
   parseJSON (Object o) = do
       Token <$> (TokenId <$> (o .: "id"))
             <*> o .: "livemode"
             <*> (fromSeconds <$> o .: "created")
             <*> o .: "used"
             <*> o .: "object"
             <*> o .: "type"
             <*> o .: "card"

---- == Invoice Item == ------
data InvoiceLineItem = InvoiceLineItem {
      invoiceLineItemId          :: Text
    , invoiceLineItemLiveMode    :: Bool
    , invoiceLineItemAmount      :: Int
    , invoiceLineItemCurrency    :: Text
    , invoiceLineItemProration   :: Bool
    , invoiceLineItemStart       :: UTCTime
    , invoiceLineItemEnd         :: UTCTime
    , invoiceLineItemQuantity    :: Maybe Int
    , invoiceLineItemPlan        :: Maybe Plan
    , invoiceLineItemDescription :: Maybe Text
  } deriving Show

---- == Invoice == ------
data Invoice = Invoice {
      invoiceDate                 :: UTCTime
    , invoiceId                   :: Text
    , invoicePeriodStart          :: UTCTime
    , invoicePeriodEnd            :: UTCTime
--    , invoiceLineItems            :: StripeList InvoiceLineItem
    , invoiceSubTotal             :: Int
    , invoiceTotal                :: Int
    , invoiceCustomer             :: Text
    , invoiceAttempted            :: Bool
    , invoiceClosed               :: Bool
    , invoiceForgiven             :: Bool
    , invoicePaid                 :: Bool
    , invoiceLiveMode             :: Bool
    , invoiceAttemptCount         :: Int
    , invoiceAmountDue            :: Int
    , invoiceCurrency             :: Text
    , invoiceStartingBalance      :: Int
    , invoiceEndingBalance        :: Maybe Int
    , invoiceNextPaymentAttempt   :: UTCTime
    , invoiceWebHooksDeliveredAt  :: UTCTime
    , invoiceCharge               :: Maybe ChargeId
    , invoiceDiscount             :: Maybe Text
    , invoiceApplicateFee         :: Maybe ApplicationFee
    , invoiceSubscription         :: SubscriptionId
    , invoiceStatementDescription :: Maybe Text
    , invoiceDescription          :: Maybe Text
} deriving Show

--- Subscriptions ---

newtype SubscriptionId = SubscriptionId Text deriving (Show, Eq)

data Subscription = Subscription {
      subscriptionId                    :: SubscriptionId
    , subscriptionPlan                  :: Plan
    , subscriptionObject                :: Text
    , subscriptionStart                 :: UTCTime
    , subscriptionStatus                :: SubscriptionStatus
    , subscriptionCustomerId            :: CustomerId
    , subscriptionCancelAtPeriodEnd     :: Bool
    , subscriptionCurrentPeriodStart    :: UTCTime
    , subscriptionCurrentPeriodEnd      :: UTCTime
    , subscriptionEndedAt               :: Maybe UTCTime
    , subscriptionTrialStart            :: Maybe UTCTime
    , subscriptionTrialEnd              :: Maybe UTCTime
    , subscriptionCanceledAt            :: Maybe UTCTime
    , subscriptionQuantity              :: Int
    , subscriptionApplicationFeePercent :: Maybe Double
    , subscriptionDiscount              :: Maybe Text
} deriving (Show, Eq)

instance FromJSON Subscription where
   parseJSON (Object o) =
       Subscription <$> (SubscriptionId <$> o .: "id")
                    <*> o .: "plan"
                    <*> o .: "object"
                    <*> o .: "start"
                    <*> o .: "status"
                    <*> (CustomerId <$> o .: "customer")
                    <*> o .: "cancel_at_period_end"
                    <*> o .: "cancel_at_period_start"
                    <*> o .: "current_period_end"
                    <*> o .:? "ended_at"
                    <*> o .:? "trial_start"
                    <*> o .:? "trial_end"
                    <*> o .:? "canceled_at"
                    <*> o .:  "quantity"
                    <*> o .:? "application_fee_percent"
                    <*> o .:? "discount"

data SubscriptionStatus =
          Trialing
        | Active
        | PastDue
        | Canceled
        | UnPaid
          deriving (Show, Eq)

instance FromJSON SubscriptionStatus where
   parseJSON (String "trialing") = pure Trialing
   parseJSON (String "active")   = pure Active
   parseJSON (String "past_due") = pure PastDue
   parseJSON (String "canceled") = pure Canceled
   parseJSON (String "unpaid")   = pure UnPaid


--- /Subscriptions ---

instance FromJSON Invoice where
   parseJSON (Object o) = undefined

instance FromJSON InvoiceLineItem where
   parseJSON (Object o) = undefined

-- https://stripe.com/docs/api#retrieve_invoiceitem
newtype InvoiceId = InvoiceId Text deriving (Show, Eq)
-- Invoice Item --
newtype InvoiceItemId = InvoiceItemId Text deriving (Eq, Show)

--- Discount --

data Discount = Discount {
      discountStart    :: Int
    , discountEnd      :: Int
    , discountCustomer :: Text
} deriving (Show, Eq)


instance FromJSON Discount where
    parseJSON (Object o) =
        Discount <$> o .: "start"
                 <*> o .: "end"
                 <*> o .: "customer"


-- Coupon --
data Duration = Forever | Once | Repeating deriving Eq

instance Show Duration where
    show Forever = "forever"
    show Once = "once"
    show Repeating = "repeating"

instance FromJSON Duration where
   parseJSON (String x)
       | x == "forever"   = pure Forever
       | x == "once"      = pure Once
       | x == "repeating" = pure Repeating
       | otherwise        = mzero

data Coupon = Coupon {
      couponId               :: Text
    , couponCreated          :: UTCTime
    , couponPercentOff       :: Int
    , couponAmountOff        :: Maybe Int
    , couponCurrency         :: Maybe Text
    , couponLiveMode         :: Bool
    , couponDuration         :: Duration
    , couponRedeemBy         :: Maybe UTCTime
    , couponMaxRedemptions   :: Maybe Int
    , couponTimesRedeemed    :: Maybe Int
    , couponDurationInMonths :: Maybe Int
    , couponValid            :: Bool
    } deriving (Show, Eq)

instance FromJSON Coupon where
   parseJSON (Object o) =
        Coupon <$> o .: "id"
               <*> (fromSeconds <$> o .: "created")
               <*> o .: "percent_off"
               <*> o .:? "amount_off"
               <*> o .:? "currency"
               <*> o .: "livemode"
               <*> o .: "duration"
               <*> (fmap fromSeconds <$> o .:? "redeem_by")
               <*> o .:? "max_redemptions"
               <*> o .:? "times_redeemed"
               <*> o .:? "duration_in_months"
               <*> o .: "valid"

newtype CouponId = CouponId Text deriving (Show, Eq)
newtype AmountOff = AmountOff Int deriving (Show, Eq)
newtype MaxRedemptions = MaxRedemptions Int deriving (Show, Eq)
newtype PercentOff = PercentOff Int deriving (Show, Eq)
newtype RedeemBy = RedeemBy UTCTime deriving (Show, Eq)
newtype DurationInMonths = DurationInMonths Int deriving (Show, Eq)

-- Plan --

newtype PlanId          = PlanId Text deriving (Show, Eq)
newtype Name            = Name Text deriving (Show, Eq)
newtype Currency        = Currency Text deriving (Show, Eq)
newtype IntervalCount   = IntervalCount Int deriving (Show, Eq)
newtype TrialPeriodDays = TrialPeriodDays Int deriving (Show, Eq)
newtype Description     = Description Text deriving (Show, Eq)
newtype Amount          = Amount Int deriving (Show, Eq)

data Interval = Week | Month | Year deriving (Eq)

instance Show Interval where
    show Week  = "week"
    show Month = "month"
    show Year  = "year"

data Plan = Plan {
      planId              :: PlanId
    , planAmount          :: Int
    , planInterval        :: Interval
    , planCreated         :: UTCTime
    , planCurrency        :: Text
    , planLiveMode        :: Bool
    , planName            :: Text
    , planIntervalCount   :: Maybe Int -- optional, max of 1 year intervals allowed, default 1
    , planTrialPeriodDays :: Maybe Int
    , planMetaData        :: Maybe Object
    , planDescription     :: Maybe Text
} deriving (Show, Eq)

instance FromJSON Plan where
   parseJSON (Object o) =
       do planId <- PlanId <$> o .: "id"
          planAmount <- o .: "amount"
          result <- o .: "interval"
          let planInterval =
                  case String result of
                    "month" -> Month
                    "week" -> Week
                    "year" -> Year
          planCreated <- fromSeconds <$> o .: "created"
          planCurrency <- o .: "currency"
          planLiveMode <- o .: "livemode"
          planName <- o .: "name"
          planIntervalCount <- o .:? "interval_count"
          planTrialPeriodDays <- o .:? "trial_period_days"
          planMetaData <- o .:? "meta_data"
          planDescription <- o .:? "statement_description"
          return Plan {..}


--- Account ---
newtype AccountId = AccountId Text deriving (Show, Eq)

data Account = Account {
       accountId                  :: AccountId
     , accountEmail               :: Text
     , accountStatementDescriptor :: Maybe Text
     , accountDisplayName         :: Text
     , accountTimeZone            :: Text
     , accountDetailsSubmitted    :: Bool
     , accountChargeEnabled       :: Bool
     , accountTransferEnabled     :: Bool
     , accountCurrenciesSupported :: [Text]
     , accountDefaultCurrency     :: Text
     , accountCountry             :: Text
     , accountObject              :: Text
} deriving (Show, Eq)

instance FromJSON Account where
   parseJSON (Object o) =
       Account <$> (AccountId <$> o .:  "id")
               <*> o .:  "email"
               <*> o .:? "statement_descriptor"
               <*> o .:  "display_name"
               <*> o .:  "timezone"
               <*> o .:  "details_submitted"
               <*> o .:  "charge_enabled"
               <*> o .:  "transfer_enabled"
               <*> o .:  "currencies_supported"
               <*> o .:  "default_currency"
               <*> o .:  "country"
               <*> o .:  "object"

-- Application Fee --
data ApplicationFee = ApplicationFee {
      applicationFeeId                 :: Text
    , applicationFeeObjecet            :: Text
    , applicationFeeCreated            :: UTCTime
    , applicationFeeLiveMode           :: Bool
    , applicationFeeAmount             :: Int
    , applicationFeeCurrency           :: Text
    , applicationFeeRefunded           :: Bool
    , applicationFeeAmountRefunded     :: Int
    , applicationFeeRefunds            :: StripeList Refund
    , applicationFeeBalanceTransaction :: TransactionId
    , applicationFeeAccountId          :: AccountId
    , applicationFeeApplicationId      :: ApplicationId
    , applicationFeeChargeId           :: ChargeId
} deriving (Show)

newtype ApplicationId = ApplicationId Text deriving (Show)

instance FromJSON ApplicationFee where
   parseJSON (Object o) =
       ApplicationFee <$> o .: "id"
                      <*> o .: "object"
                      <*> (fromSeconds <$> o .: "created")
                      <*> o .: "livemode"
                      <*> o .: "amount"
                      <*> o .: "currency"
                      <*> o .: "refunded"
                      <*> o .: "amount_refunded"
                      <*> o .: "refunds"
                      <*> (TransactionId <$> o .: "balance_transaction")
                      <*> (AccountId <$> o .: "account")
                      <*> (ApplicationId <$> o .: "application")
                      <*> (ChargeId <$> o .: "charge")



newtype FeeId = FeeId { feeId :: Text } deriving (Show, Eq)

-- Events --
newtype EventId = EventId Text deriving (Show, Eq)

data Event = Event {
      eventId      :: EventId
    , eventCreated :: UTCTime
    , eventLiveMode  :: Text
    , eventType    :: Text
} deriving (Show)

instance FromJSON Event where
   parseJSON (Object o) = 
       Event <$> (EventId <$> o .: "id")
             <*> (fromSeconds <$> o .: "created")
             <*> o .: "livemode"
             <*> o .: "type"
             

-- Balance --
data BalanceAmount = BalanceAmount {
      balanceAmount   :: Int
    , balanceCurrency :: Text
    } deriving Show

data Balance = Balance {
      balancePending   :: [BalanceAmount]
    , balanceAvailable :: [BalanceAmount]
    } deriving Show

data BalanceTransaction = BalanceTransaction {
      balanceTransactionId             :: TransactionId
    , balanceTransactionObject         :: Text
    , balanceTransactionAmount         :: Int
    , balanceTransactionCurrency       :: Text
    , balanceTransactionNet            :: Int
    , balanceTransactionType           :: Text
    , balanceTransactionCreated        :: UTCTime
    , balanceTransactionAvailableOn    :: UTCTime
    , balanceTransactionStatus         :: Text
    , balanceTransactionFee            :: Int
    , balanceTransactionFeeDetails     :: [FeeDetails]
    , balanceTransactionFeeSource      :: ChargeId
    , balanceTransactionFeeDescription :: Maybe Text
    } deriving Show


instance FromJSON BalanceTransaction where
   parseJSON (Object o) =
       BalanceTransaction <$> (TransactionId <$> o .: "id")
                          <*> o .: "object"
                          <*> o .: "amount"
                          <*> o .: "currency"
                          <*> o .: "net"
                          <*> o .: "type"
                          <*> (fromSeconds <$> o .: "created")
                          <*> (fromSeconds <$> o .: "available_on")
                          <*> o .: "status"
                          <*> o .: "fee"
                          <*> o .: "fee_details"
                          <*> (ChargeId <$> o .: "source")
                          <*> o .:? "description"
   parseJSON _ = mzero

data FeeDetails = FeeDetails {
      feeDetailsAmount   :: Int
    , feeDetailsCurrency :: Text
    , feeType            :: Text
    , feeDescription     :: Text
    , feeApplication     :: Maybe Text
} deriving (Show)

newtype TransactionId = TransactionId Text deriving (Show, Eq)

instance FromJSON FeeDetails where
   parseJSON (Object o) =
       FeeDetails <$> o .: "amount"
                  <*> o .: "currency"
                  <*> o .: "type"
                  <*> o .: "description"
                  <*> o .:? "application"
   parseJSON _ = mzero

instance FromJSON BalanceAmount where
   parseJSON (Object o) =
       BalanceAmount <$> o .: "amount"
                     <*> o .: "currency"
instance FromJSON Balance where
   parseJSON (Object o) =
       Balance <$> o .: "pending"
               <*> o .: "available"


---- Transfers
newtype RecipientId = RecipientId { recipientId :: Text } deriving (Show, Eq)
newtype TransferId = TransferId Text deriving (Show, Eq)

data TransferStatus = TransferPaid
                    | TransferPending
                    | TransferCanceled
                    | TransferFailed
                      deriving (Show, Eq)

data TransferType = CardTransfer | BankAccountTransfer deriving (Show, Eq)

instance FromJSON TransferType where
    parseJSON (String "card")         = pure CardTransfer
    parseJSON (String "bank_account") = pure BankAccountTransfer
    parseJSON _                       = mzero

instance FromJSON TransferStatus where
    parseJSON (String "paid")     = pure TransferPaid
    parseJSON (String "pending")  = pure TransferPending
    parseJSON (String "canceled") = pure TransferCanceled
    parseJSON _                   = mzero

data Transfer = Transfer {
      transferId                   :: TransferId
    , transferObject               :: Text
    , transferCreated              :: UTCTime
    , transferDate                 :: UTCTime
    , transferLiveMode             :: Bool
    , transferAmount               :: Int
    , transferCurrency             :: Text
    , transferStatus               :: TransferStatus
    , transferType                 :: TransferType
    , transferBalanceTransaction   :: TransactionId
    , transferDescription          :: Text
    , transferBankAccount          :: Account
    , transferFailureMessage       :: Maybe Text
    , transferFailureCode          :: Maybe Text
    , transferStatementDescription :: Maybe Text
    , transferRecipient            :: Maybe RecipientId
} deriving (Show)

newtype RoutingNumber = RoutingNumber Text deriving (Show, Eq)
newtype Country       = Country Text deriving (Show, Eq)
newtype AccountNumber = AccountNumber Text deriving (Show, Eq)

instance FromJSON Transfer where
    parseJSON (Object o) =
        Transfer <$> (TransferId <$> o .: "id")
                 <*> o .: "object"
                 <*> (fromSeconds <$> o .: "created")
                 <*> (fromSeconds <$> o .: "date")
                 <*> o .: "livemode"
                 <*> o .: "amount"
                 <*> o .: "currency"
                 <*> o .: "status"
                 <*> o .: "type"
                 <*> (TransactionId <$> o .: "balance_transaction")
                 <*> o .: "description"
                 <*> o .: "account"
                 <*> o .:? "failure_message"
                 <*> o .:? "failure_code"
                 <*> o .:? "statement_description"
                 <*> (fmap RecipientId <$> o .:? "recipient")

newtype ApplicationFeeRefundId = ApplicationFeeRefundId Text deriving (Show, Eq)

data ApplicationFeeRefund = ApplicationFeeRefund {
       applicationFeeRefundId                 :: ApplicationFeeRefundId
     , applicationFeeRefundAmount             :: Int
     , applicationFeeRefundCurrency           :: Text
     , applicationFeeRefundCreated            :: UTCTime
     , applicationFeeRefundObject             :: Text
     , applicationFeeRefundBalanceTransaction :: Maybe Text
     , applicationFeeRefundFee                :: FeeId
     } deriving Show

instance FromJSON ApplicationFeeRefund where
    parseJSON (Object o) = ApplicationFeeRefund
              <$> (ApplicationFeeRefundId <$> o .: "id")
              <*> o .: "amount"
              <*> o .: "currency"
              <*> (fromSeconds <$> o .: "created")
              <*> o .: "object"
              <*> o .:? "balance_transaction"
              <*> (FeeId <$> o .: "fee")


--- Disputes ---

data DisputeStatus 
    = WarningNeedsResponse
    | WarningUnderReview
    | NeedsResponse
    | UnderReview
    | ChargeRefunded
    | Won
    | Lost
    deriving (Show, Eq)

instance FromJSON DisputeReason where
   parseJSON (String "duplicate") = pure Duplicate
   parseJSON (String "fraudulent") = pure Fraudulent
   parseJSON (String "subscription_canceled") = pure SubscriptionCanceled
   parseJSON (String "product_unacceptable") = pure ProductUnacceptable
   parseJSON (String "product_not_received") = pure ProductNotReceived
   parseJSON (String "credit_not_processed") = pure CreditNotProcessed
   parseJSON (String "general") = pure General
   parseJSON _ = mzero

data DisputeReason 
    = Duplicate
    | Fraudulent
    | SubscriptionCanceled
    | ProductUnacceptable
    | ProductNotReceived
    | Unrecognized
    | CreditNotProcessed
    | General
      deriving (Show, Eq)

instance FromJSON DisputeStatus where
   parseJSON (String "needs_response") = pure NeedsResponse
   parseJSON (String "warning_needs_response") = pure WarningNeedsResponse
   parseJSON (String "warning_under_review") = pure WarningUnderReview
   parseJSON (String "under_review") = pure UnderReview
   parseJSON (String "charge_refunded") = pure ChargeRefunded
   parseJSON (String "won") = pure Won
   parseJSON (String "lost") = pure Lost
   parseJSON _ = mzero

data Dispute = Dispute {
      disputeChargeId :: ChargeId
    , disputeAmount   :: Int
    , disputeCreated  :: UTCTime
    , disputeStatus   :: DisputeStatus
    , disputeLiveMode :: Bool
    , disputeCurrency :: Currency
    , disputeObject   :: DisputeReason
    , disputeReason   :: Text
    , disputeIsChargeRefundable :: Bool
    , disputeBalanceTransactions :: [Text]
    , disputeEvidenceDueBy :: UTCTime
    , disputeEvidence :: Maybe Text
    } deriving (Show)

newtype Evidence = Evidence Text deriving (Show, Eq)

instance FromJSON Dispute where
    parseJSON (Object o) = 
        Dispute <$> (ChargeId <$> o .: "charge")
                <*> o .: "amount"
                <*> (fromSeconds <$> o .: "created")
                <*> o .: "status"
                <*> o .: "live_mode"
                <*> (Currency <$> o .: "currency")
                <*> o .: "object"
                <*> o .: "reason"
                <*> o .: "is_charge_refundable"
                <*> o .: "balance_transactions"
                <*> (fromSeconds <$> o .: "evidence_due_by")
                <*> o .:? "evidency"
                

