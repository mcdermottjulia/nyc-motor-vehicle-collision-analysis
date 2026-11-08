// NYC Motor Vehicle Collision Analysis | MongoDB aggregation exploration
// Aggregation queries for the imported nyc_crashes.crashes collection.
// Run in mongosh after importing the corresponding CSV snapshot.
// Source-versus-import differences are documented in docs/data_validation_notes.md.

const crashes = db.getSiblingDB("nyc_crashes").getCollection("crashes");

// A. Sample record for a named borough
print("\nSAMPLE BROOKLYN RECORD:");
printjson(crashes.findOne({ BOROUGH: "BROOKLYN" }));

// B. NOMINAL: collision counts by borough
print("\nCOLLISIONS BY BOROUGH:");
printjson(crashes.aggregate([
  { $group: { _id: "$BOROUGH", crash_count: { $sum: 1 } } },
  { $sort: { crash_count: -1 } }
]).toArray());

// C. ORDINAL: crash-impact categories
// Uses the imported field values; missing-value differences are documented separately.
print("\nCRASH IMPACT COUNTS:");
printjson(crashes.aggregate([
  {
    $addFields: {
      "Crash Impact": {
        $switch: {
          branches: [
            { case: { $gt: ["$NUMBER OF PERSONS KILLED", 0] }, then: "Fatality" },
            { case: { $gt: ["$NUMBER OF PERSONS INJURED", 0] }, then: "Injury" },
            {
              case: {
                $and: [
                  { $eq: ["$NUMBER OF PERSONS INJURED", 0] },
                  { $eq: ["$NUMBER OF PERSONS KILLED", 0] }
                ]
              },
              then: "No Injury"
            }
          ],
          default: "Unknown"
        }
      }
    }
  },
  { $group: { _id: "$Crash Impact", crash_count: { $sum: 1 } } },
  { $sort: { crash_count: -1 } }
]).toArray());

// D. INTERVAL: min/max crash date
// The course CSV used MM/DD/YYYY strings at import time.
print("\nDATE RANGE:");
printjson(crashes.aggregate([
  {
    $addFields: {
      crash_date_converted: {
        $dateFromString: { dateString: "$CRASH DATE", format: "%m/%d/%Y" }
      }
    }
  },
  {
    $group: {
      _id: null,
      earliest_crash: { $min: "$crash_date_converted" },
      latest_crash: { $max: "$crash_date_converted" }
    }
  }
]).toArray());

// E. RATIO: persons injured per crash
// $stdDevPop calculates population standard deviation (as used in MySQL).
print("\nNUMBER OF PERSONS INJURED:");
printjson(crashes.aggregate([
  {
    $group: {
      _id: null,
      count: { $sum: 1 },
      minimum: { $min: "$NUMBER OF PERSONS INJURED" },
      maximum: { $max: "$NUMBER OF PERSONS INJURED" },
      mean: { $avg: "$NUMBER OF PERSONS INJURED" },
      population_std_dev: { $stdDevPop: "$NUMBER OF PERSONS INJURED" }
    }
  }
]).toArray());
