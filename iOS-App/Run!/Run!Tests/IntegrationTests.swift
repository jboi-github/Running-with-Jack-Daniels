//
//  IntegrationTests.swift
//  Run!Tests
//
//  Created by Jürgen Boiselle on 21.11.21.
//

import XCTest
@testable import Run_
import CoreMotion
import CoreBluetooth
import CoreLocation

// DONE: (Today) Minimize collect and compare functions to work/notwork switches
// TODO: (This week) Manually create expected values via Excel. Drop collect functions
// DONE: (Today) Add tests for only one producer is working
// DONE: (Today) Merge path service test here
// TODO: (This week) Add performance tests
// TODO: (Next week) Create UI Tests from Gallery. Try TDD approach.
// TODO: (Next week) Add more UI-Elements and views

class IntegrationTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        print(" --- SET UP --- ")
        print(PathService.sharedInstance.path.count)
        print(HrGraphService.sharedInstance.graph.count)
        print(CurrentsService.sharedInstance.isActive.isActive)
        print(TotalsService.sharedInstance.totals.count)
        print(ProfileService.sharedInstance.birthday.value ?? .distantPast)
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        testData.removeAll()
        compareData.removeAll()
        print(" --- TEAR DOWN --- ")
    }
    
    /**
     Create some integration tests for:
     - Normal operations: GPS, BLE and ACL are allowed and working (1 case)
     - One case were each is dis-allowed, but the rest is allowed (3 cases)
     - One case were each is not working, but the rest is allowed (3 cases)
     - One case were one is allowed, but the rest is not (3 cases)
     - One case were one is working, but the rest is not (3 cases)
     - Minimal operations: Non is allowed (1 case)
     - Minimal operations: Non is working (1 case)
     
     All cases get the same data:
     - Locations taken from a downloaded track
     - Timstamps to be added
     - Heartrates every second
     - Active/inActive events, changing from pause to walk, run, cycle, pause, run, pause.
     */
    
    enum Action {
        case location(seconds: TimeInterval, latitude: CLLocationDegrees, longitude: CLLocationDegrees)
        case heartrate(seconds: TimeInterval, heartrate: Int)
        case motion(seconds: TimeInterval, idx: Int)
    }
    
    let actions: [Action] = [
        .heartrate(seconds: 7, heartrate: 50),
        .heartrate(seconds: 12, heartrate: 55),
        .heartrate(seconds: 17, heartrate: 60),
        .heartrate(seconds: 22, heartrate: 65),
        .heartrate(seconds: 27, heartrate: 70),
        .location(seconds: 31, latitude: 49.714157506945, longitude: 9.27123500981339),
        .heartrate(seconds: 32, heartrate: 75),
        .heartrate(seconds: 37, heartrate: 80),
        .heartrate(seconds: 42, heartrate: 85),
        .heartrate(seconds: 47, heartrate: 90),
        .heartrate(seconds: 52, heartrate: 95),
        .heartrate(seconds: 57, heartrate: 100),
        .location(seconds: 61, latitude: 49.7144363137203, longitude: 9.2701891463517),
        .heartrate(seconds: 62, heartrate: 105),
        .motion(seconds: 59, idx: 0),
        .heartrate(seconds: 67, heartrate: 110),
        .heartrate(seconds: 72, heartrate: 115),
        .heartrate(seconds: 77, heartrate: 120),
        .heartrate(seconds: 82, heartrate: 125),
        .heartrate(seconds: 87, heartrate: 130),
        .location(seconds: 91, latitude: 49.7146735948198, longitude: 9.26904695335765),
        .heartrate(seconds: 92, heartrate: 135),
        .heartrate(seconds: 97, heartrate: 140),
        .heartrate(seconds: 102, heartrate: 145),
        .heartrate(seconds: 107, heartrate: 150),
        .heartrate(seconds: 112, heartrate: 155),
        .heartrate(seconds: 117, heartrate: 160),
        .location(seconds: 121, latitude: 49.7150710380709, longitude: 9.2677900823589),
        .heartrate(seconds: 122, heartrate: 165),
        .motion(seconds: 119, idx: 1),
        .heartrate(seconds: 127, heartrate: 170),
        .heartrate(seconds: 132, heartrate: 175),
        .heartrate(seconds: 137, heartrate: 180),
        .heartrate(seconds: 142, heartrate: 185),
        .heartrate(seconds: 147, heartrate: 180),
        .location(seconds: 151, latitude: 49.7154091588674, longitude: 9.26677632873767),
        .heartrate(seconds: 152, heartrate: 175),
        .heartrate(seconds: 157, heartrate: 170),
        .heartrate(seconds: 162, heartrate: 165),
        .heartrate(seconds: 167, heartrate: 160),
        .heartrate(seconds: 172, heartrate: 155),
        .heartrate(seconds: 177, heartrate: 150),
        .location(seconds: 181, latitude: 49.7154951716865, longitude: 9.26652862424016),
        .heartrate(seconds: 182, heartrate: 145),
        .motion(seconds: 179, idx: 2),
        .heartrate(seconds: 187, heartrate: 140),
        .heartrate(seconds: 192, heartrate: 135),
        .heartrate(seconds: 197, heartrate: 130),
        .heartrate(seconds: 202, heartrate: 125),
        .heartrate(seconds: 207, heartrate: 120),
        .location(seconds: 211, latitude: 49.7159756542404, longitude: 9.26485432527843),
        .heartrate(seconds: 212, heartrate: 115),
        .heartrate(seconds: 217, heartrate: 110),
        .heartrate(seconds: 222, heartrate: 105),
        .heartrate(seconds: 227, heartrate: 100),
        .heartrate(seconds: 232, heartrate: 95),
        .heartrate(seconds: 237, heartrate: 90),
        .location(seconds: 241, latitude: 49.7168476289596, longitude: 9.26536349564731),
        .heartrate(seconds: 242, heartrate: 85),
        .motion(seconds: 239, idx: 3),
        .heartrate(seconds: 247, heartrate: 80),
        .heartrate(seconds: 252, heartrate: 75),
        .heartrate(seconds: 257, heartrate: 70),
        .heartrate(seconds: 262, heartrate: 65),
        .heartrate(seconds: 267, heartrate: 60),
        .location(seconds: 271, latitude: 49.7181259037245, longitude: 9.26595523418507),
        .heartrate(seconds: 272, heartrate: 55),
        .heartrate(seconds: 277, heartrate: 50),
        .heartrate(seconds: 282, heartrate: 45),
        .heartrate(seconds: 287, heartrate: 50),
        .heartrate(seconds: 292, heartrate: 55),
        .heartrate(seconds: 297, heartrate: 60),
        .location(seconds: 301, latitude: 49.7188643812558, longitude: 9.26629009397571),
        .heartrate(seconds: 302, heartrate: 65),
        .motion(seconds: 299, idx: 2),
        .heartrate(seconds: 307, heartrate: 70),
        .heartrate(seconds: 312, heartrate: 75),
        .heartrate(seconds: 317, heartrate: 80),
        .heartrate(seconds: 322, heartrate: 85),
        .heartrate(seconds: 327, heartrate: 90),
        .location(seconds: 331, latitude: 49.7193893162652, longitude: 9.26656532120319),
        .heartrate(seconds: 332, heartrate: 95),
        .heartrate(seconds: 337, heartrate: 100),
        .heartrate(seconds: 342, heartrate: 105),
        .heartrate(seconds: 347, heartrate: 110),
        .heartrate(seconds: 352, heartrate: 115),
        .heartrate(seconds: 357, heartrate: 120),
        .location(seconds: 361, latitude: 49.7197540982687, longitude: 9.26708366581495),
        .heartrate(seconds: 362, heartrate: 125),
        .motion(seconds: 359, idx: 1),
        .heartrate(seconds: 367, heartrate: 130),
        .heartrate(seconds: 372, heartrate: 135),
        .heartrate(seconds: 377, heartrate: 140),
        .heartrate(seconds: 382, heartrate: 145),
        .heartrate(seconds: 387, heartrate: 150),
        .location(seconds: 391, latitude: 49.7199883877213, longitude: 9.26732219607581),
        .heartrate(seconds: 392, heartrate: 155),
        .heartrate(seconds: 397, heartrate: 160),
        .heartrate(seconds: 402, heartrate: 165),
        .heartrate(seconds: 407, heartrate: 170),
        .heartrate(seconds: 412, heartrate: 175),
        .heartrate(seconds: 417, heartrate: 180),
        .location(seconds: 421, latitude: 49.7202197103582, longitude: 9.26739559000313),
        .heartrate(seconds: 422, heartrate: 185),
        .motion(seconds: 419, idx: 0),
        .heartrate(seconds: 427, heartrate: 180),
        .heartrate(seconds: 432, heartrate: 175),
        .heartrate(seconds: 437, heartrate: 170),
        .heartrate(seconds: 442, heartrate: 165),
        .heartrate(seconds: 447, heartrate: 160),
        .location(seconds: 451, latitude: 49.7206230395134, longitude: 9.26712953701659),
        .heartrate(seconds: 452, heartrate: 155),
        .heartrate(seconds: 457, heartrate: 150),
        .heartrate(seconds: 462, heartrate: 145),
        .heartrate(seconds: 467, heartrate: 140),
        .heartrate(seconds: 472, heartrate: 135),
        .heartrate(seconds: 477, heartrate: 130),
        .location(seconds: 481, latitude: 49.7211865084392, longitude: 9.26723962790758),
        .heartrate(seconds: 482, heartrate: 125),
        .motion(seconds: 479, idx: 1),
        .heartrate(seconds: 487, heartrate: 120),
        .heartrate(seconds: 492, heartrate: 115),
        .heartrate(seconds: 497, heartrate: 110),
        .heartrate(seconds: 502, heartrate: 105),
        .heartrate(seconds: 507, heartrate: 100),
        .location(seconds: 511, latitude: 49.722301564533, longitude: 9.26761577178362),
        .heartrate(seconds: 512, heartrate: 95),
        .heartrate(seconds: 517, heartrate: 90),
        .heartrate(seconds: 522, heartrate: 85),
        .heartrate(seconds: 527, heartrate: 80),
        .heartrate(seconds: 532, heartrate: 75),
        .heartrate(seconds: 537, heartrate: 70),
        .location(seconds: 541, latitude: 49.7238406557587, longitude: 9.26806530958582),
        .heartrate(seconds: 542, heartrate: 65),
        .motion(seconds: 539, idx: 2),
        .heartrate(seconds: 547, heartrate: 60),
        .heartrate(seconds: 552, heartrate: 55),
        .heartrate(seconds: 557, heartrate: 50),
        .heartrate(seconds: 562, heartrate: 45),
        .heartrate(seconds: 567, heartrate: 50),
        .location(seconds: 571, latitude: 49.726032071371, longitude: 9.26890016550582),
        .heartrate(seconds: 572, heartrate: 55),
        .heartrate(seconds: 577, heartrate: 60),
        .heartrate(seconds: 582, heartrate: 65),
        .heartrate(seconds: 587, heartrate: 70),
        .heartrate(seconds: 592, heartrate: 75),
        .heartrate(seconds: 597, heartrate: 80),
        .location(seconds: 601, latitude: 49.7260409673084, longitude: 9.26881759733758),
        .heartrate(seconds: 602, heartrate: 85),
        .motion(seconds: 599, idx: 3),
        .heartrate(seconds: 607, heartrate: 90),
        .heartrate(seconds: 612, heartrate: 95),
        .heartrate(seconds: 617, heartrate: 100),
        .heartrate(seconds: 622, heartrate: 105),
        .heartrate(seconds: 627, heartrate: 110),
        .location(seconds: 631, latitude: 49.7259490425431, longitude: 9.26866622236246),
        .heartrate(seconds: 632, heartrate: 115),
        .heartrate(seconds: 637, heartrate: 120),
        .heartrate(seconds: 642, heartrate: 125),
        .heartrate(seconds: 647, heartrate: 130),
        .heartrate(seconds: 652, heartrate: 135),
        .heartrate(seconds: 657, heartrate: 140),
        .location(seconds: 661, latitude: 49.7258274643603, longitude: 9.26794145733009),
        .heartrate(seconds: 662, heartrate: 145),
        .motion(seconds: 659, idx: 2),
        .heartrate(seconds: 667, heartrate: 150),
        .heartrate(seconds: 672, heartrate: 155),
        .heartrate(seconds: 677, heartrate: 160),
        .heartrate(seconds: 682, heartrate: 165),
        .heartrate(seconds: 687, heartrate: 170),
        .location(seconds: 691, latitude: 49.7257414698521, longitude: 9.26781301795727),
        .heartrate(seconds: 692, heartrate: 175),
        .heartrate(seconds: 697, heartrate: 180),
        .heartrate(seconds: 702, heartrate: 185),
        .heartrate(seconds: 707, heartrate: 180),
        .heartrate(seconds: 712, heartrate: 175),
        .heartrate(seconds: 717, heartrate: 170),
        .location(seconds: 721, latitude: 49.7253648714182, longitude: 9.26770292706627),
        .heartrate(seconds: 722, heartrate: 165),
        .motion(seconds: 719, idx: 1),
        .heartrate(seconds: 727, heartrate: 160),
        .heartrate(seconds: 732, heartrate: 155),
        .heartrate(seconds: 737, heartrate: 150),
        .heartrate(seconds: 742, heartrate: 145),
        .heartrate(seconds: 747, heartrate: 140),
        .location(seconds: 751, latitude: 49.7241846463518, longitude: 9.2673772415166),
        .heartrate(seconds: 752, heartrate: 135),
        .heartrate(seconds: 757, heartrate: 130),
        .heartrate(seconds: 762, heartrate: 125),
        .heartrate(seconds: 767, heartrate: 120),
        .heartrate(seconds: 772, heartrate: 115),
        .heartrate(seconds: 777, heartrate: 110),
        .location(seconds: 781, latitude: 49.7228887380443, longitude: 9.26716164685649),
        .heartrate(seconds: 782, heartrate: 105),
        .motion(seconds: 779, idx: 0),
        .heartrate(seconds: 787, heartrate: 100),
        .heartrate(seconds: 792, heartrate: 95),
        .heartrate(seconds: 797, heartrate: 90),
        .heartrate(seconds: 802, heartrate: 85),
        .heartrate(seconds: 807, heartrate: 80),
        .location(seconds: 811, latitude: 49.7221424582182, longitude: 9.26693861304293),
        .heartrate(seconds: 812, heartrate: 75),
        .heartrate(seconds: 817, heartrate: 70),
        .heartrate(seconds: 822, heartrate: 65),
        .heartrate(seconds: 827, heartrate: 60),
        .heartrate(seconds: 832, heartrate: 55),
        .heartrate(seconds: 837, heartrate: 50),
        .location(seconds: 841, latitude: 49.7221424582182, longitude: 9.26699050903849),
        .heartrate(seconds: 842, heartrate: 45),
        .motion(seconds: 839, idx: 1),
        .heartrate(seconds: 847, heartrate: 50),
        .heartrate(seconds: 852, heartrate: 55),
        .heartrate(seconds: 857, heartrate: 60),
        .heartrate(seconds: 862, heartrate: 65),
        .heartrate(seconds: 867, heartrate: 70),
        .location(seconds: 871, latitude: 49.7212030350796, longitude: 9.26668778240197),
        .heartrate(seconds: 872, heartrate: 75),
        .heartrate(seconds: 877, heartrate: 80),
        .heartrate(seconds: 882, heartrate: 85),
        .heartrate(seconds: 887, heartrate: 90),
        .heartrate(seconds: 892, heartrate: 95),
        .heartrate(seconds: 897, heartrate: 100),
        .location(seconds: 901, latitude: 49.7209849521179, longitude: 9.26660128907604),
        .heartrate(seconds: 902, heartrate: 105),
        .motion(seconds: 899, idx: 2),
        .heartrate(seconds: 907, heartrate: 110),
        .heartrate(seconds: 912, heartrate: 115),
        .heartrate(seconds: 917, heartrate: 120),
        .heartrate(seconds: 922, heartrate: 125),
        .heartrate(seconds: 927, heartrate: 130),
        .location(seconds: 931, latitude: 49.7206829894768, longitude: 9.26703375570569),
        .heartrate(seconds: 932, heartrate: 135),
        .heartrate(seconds: 937, heartrate: 140),
        .heartrate(seconds: 942, heartrate: 145),
        .heartrate(seconds: 947, heartrate: 150),
        .heartrate(seconds: 952, heartrate: 155),
        .heartrate(seconds: 957, heartrate: 160),
        .location(seconds: 961, latitude: 49.7202020821345, longitude: 9.26690401571679),
        .heartrate(seconds: 962, heartrate: 165),
        .motion(seconds: 959, idx: 3),
        .heartrate(seconds: 967, heartrate: 170),
        .heartrate(seconds: 972, heartrate: 175),
        .heartrate(seconds: 977, heartrate: 180),
        .heartrate(seconds: 982, heartrate: 185),
        .heartrate(seconds: 987, heartrate: 180),
        .location(seconds: 991, latitude: 49.7198497865022, longitude: 9.2665839904141),
        .heartrate(seconds: 992, heartrate: 175),
        .heartrate(seconds: 997, heartrate: 170),
        .heartrate(seconds: 1002, heartrate: 165),
        .heartrate(seconds: 1007, heartrate: 160),
        .heartrate(seconds: 1012, heartrate: 155),
        .heartrate(seconds: 1017, heartrate: 150),
        .location(seconds: 1021, latitude: 49.7199392586455, longitude: 9.2660823291237),
        .heartrate(seconds: 1022, heartrate: 145),
        .motion(seconds: 1019, idx: 2),
        .heartrate(seconds: 1027, heartrate: 140),
        .heartrate(seconds: 1032, heartrate: 135),
        .heartrate(seconds: 1037, heartrate: 130),
        .heartrate(seconds: 1042, heartrate: 125),
        .heartrate(seconds: 1047, heartrate: 120),
        .location(seconds: 1051, latitude: 49.7199057066111, longitude: 9.26560661583108),
        .heartrate(seconds: 1052, heartrate: 115),
        .heartrate(seconds: 1057, heartrate: 110),
        .heartrate(seconds: 1062, heartrate: 105),
        .heartrate(seconds: 1067, heartrate: 100),
        .heartrate(seconds: 1072, heartrate: 95),
        .heartrate(seconds: 1077, heartrate: 90),
        .location(seconds: 1081, latitude: 49.7195254486008, longitude: 9.26568445982442),
        .heartrate(seconds: 1082, heartrate: 85),
        .motion(seconds: 1079, idx: 1),
        .heartrate(seconds: 1087, heartrate: 80),
        .heartrate(seconds: 1092, heartrate: 75),
        .heartrate(seconds: 1097, heartrate: 70),
        .heartrate(seconds: 1102, heartrate: 65),
        .heartrate(seconds: 1107, heartrate: 60),
        .location(seconds: 1111, latitude: 49.7190277534705, longitude: 9.26532118785551),
        .heartrate(seconds: 1112, heartrate: 55),
        .heartrate(seconds: 1117, heartrate: 50),
        .heartrate(seconds: 1122, heartrate: 45),
        .heartrate(seconds: 1127, heartrate: 50),
        .heartrate(seconds: 1132, heartrate: 55),
        .heartrate(seconds: 1137, heartrate: 60),
        .location(seconds: 1141, latitude: 49.7189215032875, longitude: 9.26519144786661),
        .heartrate(seconds: 1142, heartrate: 65),
        .motion(seconds: 1139, idx: 0),
        .heartrate(seconds: 1147, heartrate: 70),
        .heartrate(seconds: 1152, heartrate: 75),
        .heartrate(seconds: 1157, heartrate: 80),
        .heartrate(seconds: 1162, heartrate: 85),
        .heartrate(seconds: 1167, heartrate: 90),
        .location(seconds: 1171, latitude: 49.7186586728887, longitude: 9.26525199319476),
        .heartrate(seconds: 1172, heartrate: 95),
        .heartrate(seconds: 1177, heartrate: 100),
        .heartrate(seconds: 1182, heartrate: 105),
        .heartrate(seconds: 1187, heartrate: 110),
        .heartrate(seconds: 1192, heartrate: 115),
        .heartrate(seconds: 1197, heartrate: 120),
        .location(seconds: 1201, latitude: 49.7182448519307, longitude: 9.26510495454068),
        .heartrate(seconds: 1202, heartrate: 125),
        .motion(seconds: 1199, idx: 1),
        .heartrate(seconds: 1207, heartrate: 130),
        .heartrate(seconds: 1212, heartrate: 135),
        .heartrate(seconds: 1217, heartrate: 140),
        .heartrate(seconds: 1222, heartrate: 145),
        .heartrate(seconds: 1227, heartrate: 150),
        .location(seconds: 1231, latitude: 49.7173221302904, longitude: 9.26475898124513),
        .heartrate(seconds: 1232, heartrate: 155),
        .heartrate(seconds: 1237, heartrate: 160),
        .heartrate(seconds: 1242, heartrate: 165),
        .heartrate(seconds: 1247, heartrate: 170),
        .heartrate(seconds: 1252, heartrate: 175),
        .heartrate(seconds: 1257, heartrate: 180),
        .location(seconds: 1261, latitude: 49.7172102840577, longitude: 9.26456004659548),
        .heartrate(seconds: 1262, heartrate: 185),
        .motion(seconds: 1259, idx: 2),
        .heartrate(seconds: 1267, heartrate: 180),
        .heartrate(seconds: 1272, heartrate: 175),
        .heartrate(seconds: 1277, heartrate: 170),
        .heartrate(seconds: 1282, heartrate: 165),
        .heartrate(seconds: 1287, heartrate: 160),
        .location(seconds: 1291, latitude: 49.7169865908193, longitude: 9.26424867062213),
        .heartrate(seconds: 1292, heartrate: 155),
        .heartrate(seconds: 1297, heartrate: 150),
        .heartrate(seconds: 1302, heartrate: 145),
        .heartrate(seconds: 1307, heartrate: 140),
        .heartrate(seconds: 1312, heartrate: 135),
        .heartrate(seconds: 1317, heartrate: 130),
        .location(seconds: 1321, latitude: 49.716432945623, longitude: 9.26382485332507),
        .heartrate(seconds: 1322, heartrate: 125),
        .motion(seconds: 1319, idx: 3),
        .heartrate(seconds: 1327, heartrate: 120),
        .heartrate(seconds: 1332, heartrate: 115),
        .heartrate(seconds: 1337, heartrate: 110),
        .heartrate(seconds: 1342, heartrate: 105),
        .heartrate(seconds: 1347, heartrate: 100),
        .location(seconds: 1351, latitude: 49.7162707655319, longitude: 9.26371241200136),
        .heartrate(seconds: 1352, heartrate: 95),
        .heartrate(seconds: 1357, heartrate: 90),
        .heartrate(seconds: 1362, heartrate: 85),
        .heartrate(seconds: 1367, heartrate: 80),
        .heartrate(seconds: 1372, heartrate: 75),
        .heartrate(seconds: 1377, heartrate: 70),
        .location(seconds: 1381, latitude: 49.7156500022083, longitude: 9.2634702306951),
        .heartrate(seconds: 1382, heartrate: 65),
        .motion(seconds: 1379, idx: 2),
        .heartrate(seconds: 1387, heartrate: 60),
        .heartrate(seconds: 1392, heartrate: 55),
        .heartrate(seconds: 1397, heartrate: 50),
        .heartrate(seconds: 1402, heartrate: 45),
        .heartrate(seconds: 1407, heartrate: 50),
        .location(seconds: 1411, latitude: 49.714637749564, longitude: 9.26300316673507),
        .heartrate(seconds: 1412, heartrate: 55),
        .heartrate(seconds: 1417, heartrate: 60),
        .heartrate(seconds: 1422, heartrate: 65),
        .heartrate(seconds: 1427, heartrate: 70),
        .heartrate(seconds: 1432, heartrate: 75),
        .heartrate(seconds: 1437, heartrate: 80),
        .location(seconds: 1441, latitude: 49.7136142903103, longitude: 9.26219012948033),
        .heartrate(seconds: 1442, heartrate: 85),
        .motion(seconds: 1439, idx: 1),
        .heartrate(seconds: 1447, heartrate: 90),
        .heartrate(seconds: 1452, heartrate: 95),
        .heartrate(seconds: 1457, heartrate: 100),
        .heartrate(seconds: 1462, heartrate: 105),
        .heartrate(seconds: 1467, heartrate: 110),
        .location(seconds: 1471, latitude: 49.7125852166856, longitude: 9.26158467619881),
        .heartrate(seconds: 1472, heartrate: 115),
        .heartrate(seconds: 1477, heartrate: 120),
        .heartrate(seconds: 1482, heartrate: 125),
        .heartrate(seconds: 1487, heartrate: 130),
        .heartrate(seconds: 1492, heartrate: 135),
        .heartrate(seconds: 1497, heartrate: 140),
        .location(seconds: 1501, latitude: 49.7121489723726, longitude: 9.26142898821214),
        .heartrate(seconds: 1502, heartrate: 145),
        .motion(seconds: 1499, idx: 0),
        .heartrate(seconds: 1507, heartrate: 150),
        .heartrate(seconds: 1512, heartrate: 155),
        .heartrate(seconds: 1517, heartrate: 160),
        .heartrate(seconds: 1522, heartrate: 165),
        .heartrate(seconds: 1527, heartrate: 170),
        .location(seconds: 1531, latitude: 49.7118525477191, longitude: 9.26132519622102),
        .heartrate(seconds: 1532, heartrate: 175),
        .heartrate(seconds: 1537, heartrate: 180),
        .heartrate(seconds: 1542, heartrate: 185),
        .heartrate(seconds: 1547, heartrate: 180),
        .heartrate(seconds: 1552, heartrate: 175),
        .heartrate(seconds: 1557, heartrate: 170),
        .location(seconds: 1561, latitude: 49.7121042291305, longitude: 9.26261394677473),
        .heartrate(seconds: 1562, heartrate: 165),
        .motion(seconds: 1559, idx: 1),
        .heartrate(seconds: 1567, heartrate: 160),
        .heartrate(seconds: 1572, heartrate: 155),
        .heartrate(seconds: 1577, heartrate: 150),
        .heartrate(seconds: 1582, heartrate: 145),
        .heartrate(seconds: 1587, heartrate: 140),
        .location(seconds: 1591, latitude: 49.7120427071247, longitude: 9.26422272263705),
        .heartrate(seconds: 1592, heartrate: 135),
        .heartrate(seconds: 1597, heartrate: 130),
        .heartrate(seconds: 1602, heartrate: 125),
        .heartrate(seconds: 1607, heartrate: 120),
        .heartrate(seconds: 1612, heartrate: 115),
        .heartrate(seconds: 1617, heartrate: 110),
        .location(seconds: 1621, latitude: 49.7121042291305, longitude: 9.26493196790969),
        .heartrate(seconds: 1622, heartrate: 105),
        .motion(seconds: 1619, idx: 2),
        .heartrate(seconds: 1627, heartrate: 100),
        .heartrate(seconds: 1632, heartrate: 95),
        .heartrate(seconds: 1637, heartrate: 90),
        .heartrate(seconds: 1642, heartrate: 85),
        .heartrate(seconds: 1647, heartrate: 80),
        .location(seconds: 1651, latitude: 49.7118861053037, longitude: 9.26503575990081),
        .heartrate(seconds: 1652, heartrate: 75),
        .heartrate(seconds: 1657, heartrate: 70),
        .heartrate(seconds: 1662, heartrate: 65),
        .heartrate(seconds: 1667, heartrate: 60),
        .heartrate(seconds: 1672, heartrate: 55),
        .heartrate(seconds: 1677, heartrate: 50),
        .location(seconds: 1681, latitude: 49.7118581406397, longitude: 9.26406703465038),
        .heartrate(seconds: 1682, heartrate: 45),
        .motion(seconds: 1679, idx: 3),
        .heartrate(seconds: 1687, heartrate: 50),
        .heartrate(seconds: 1692, heartrate: 55),
        .heartrate(seconds: 1697, heartrate: 60),
        .heartrate(seconds: 1702, heartrate: 65),
        .heartrate(seconds: 1707, heartrate: 70),
        .location(seconds: 1711, latitude: 49.7119196628793, longitude: 9.2626571934377),
        .heartrate(seconds: 1712, heartrate: 75),
        .heartrate(seconds: 1717, heartrate: 80),
        .heartrate(seconds: 1722, heartrate: 85),
        .heartrate(seconds: 1727, heartrate: 90),
        .heartrate(seconds: 1732, heartrate: 95),
        .heartrate(seconds: 1737, heartrate: 100),
        .location(seconds: 1741, latitude: 49.7118805123722, longitude: 9.26235446679694),
        .heartrate(seconds: 1742, heartrate: 105),
        .motion(seconds: 1739, idx: 2),
        .heartrate(seconds: 1747, heartrate: 110),
        .heartrate(seconds: 1752, heartrate: 115),
        .heartrate(seconds: 1757, heartrate: 120),
        .heartrate(seconds: 1762, heartrate: 125),
        .heartrate(seconds: 1767, heartrate: 130),
        .location(seconds: 1771, latitude: 49.7116735734533, longitude: 9.26180955884357),
        .heartrate(seconds: 1772, heartrate: 135),
        .heartrate(seconds: 1777, heartrate: 140),
        .heartrate(seconds: 1782, heartrate: 145),
        .heartrate(seconds: 1787, heartrate: 150),
        .heartrate(seconds: 1792, heartrate: 155),
        .heartrate(seconds: 1797, heartrate: 160),
        .location(seconds: 1801, latitude: 49.7114162968112, longitude: 9.26139439087911),
        .heartrate(seconds: 1802, heartrate: 165),
        .motion(seconds: 1799, idx: 1),
        .heartrate(seconds: 1807, heartrate: 170),
        .heartrate(seconds: 1812, heartrate: 175),
        .heartrate(seconds: 1817, heartrate: 180),
        .heartrate(seconds: 1822, heartrate: 185),
        .heartrate(seconds: 1827, heartrate: 180),
        .location(seconds: 1831, latitude: 49.7108122506434, longitude: 9.26110031357094),
        .heartrate(seconds: 1832, heartrate: 175),
        .heartrate(seconds: 1837, heartrate: 170),
        .heartrate(seconds: 1842, heartrate: 165),
        .heartrate(seconds: 1847, heartrate: 160),
        .heartrate(seconds: 1852, heartrate: 155),
        .heartrate(seconds: 1857, heartrate: 150),
        .location(seconds: 1861, latitude: 49.7098446424593, longitude: 9.26072839228337),
        .heartrate(seconds: 1862, heartrate: 145),
        .motion(seconds: 1859, idx: 0),
        .heartrate(seconds: 1867, heartrate: 140),
        .heartrate(seconds: 1872, heartrate: 135),
        .heartrate(seconds: 1877, heartrate: 130),
        .heartrate(seconds: 1882, heartrate: 125),
        .heartrate(seconds: 1887, heartrate: 120),
        .location(seconds: 1891, latitude: 49.7092573564507, longitude: 9.26026132832334),
        .heartrate(seconds: 1892, heartrate: 115),
        .heartrate(seconds: 1897, heartrate: 110),
        .heartrate(seconds: 1902, heartrate: 105),
        .heartrate(seconds: 1907, heartrate: 100),
        .heartrate(seconds: 1912, heartrate: 95),
        .heartrate(seconds: 1917, heartrate: 90),
        .location(seconds: 1921, latitude: 49.7088490486603, longitude: 9.26020943232778),
        .heartrate(seconds: 1922, heartrate: 85),
        .motion(seconds: 1919, idx: 1),
        .heartrate(seconds: 1927, heartrate: 80),
        .heartrate(seconds: 1932, heartrate: 75),
        .heartrate(seconds: 1937, heartrate: 70),
        .heartrate(seconds: 1942, heartrate: 65),
        .heartrate(seconds: 1947, heartrate: 60),
        .location(seconds: 1951, latitude: 49.7084742973937, longitude: 9.26003644567592),
        .heartrate(seconds: 1952, heartrate: 55),
        .heartrate(seconds: 1957, heartrate: 50),
        .heartrate(seconds: 1962, heartrate: 45),
        .heartrate(seconds: 1967, heartrate: 50),
        .heartrate(seconds: 1972, heartrate: 55),
        .heartrate(seconds: 1977, heartrate: 60),
        .location(seconds: 1981, latitude: 49.7077751268143, longitude: 9.25987210835835),
        .heartrate(seconds: 1982, heartrate: 65),
        .motion(seconds: 1979, idx: 2),
        .heartrate(seconds: 1987, heartrate: 70),
        .heartrate(seconds: 1992, heartrate: 75),
        .heartrate(seconds: 1997, heartrate: 80),
        .heartrate(seconds: 2002, heartrate: 85),
        .heartrate(seconds: 2007, heartrate: 90),
        .location(seconds: 2011, latitude: 49.7073612131129, longitude: 9.25975966703464),
        .heartrate(seconds: 2012, heartrate: 95),
        .heartrate(seconds: 2017, heartrate: 100),
        .heartrate(seconds: 2022, heartrate: 105),
        .heartrate(seconds: 2027, heartrate: 110),
        .heartrate(seconds: 2032, heartrate: 115),
        .heartrate(seconds: 2037, heartrate: 120),
        .location(seconds: 2041, latitude: 49.7071262875512, longitude: 9.26041701631172),
        .heartrate(seconds: 2042, heartrate: 125),
        .motion(seconds: 2039, idx: 3),
        .heartrate(seconds: 2047, heartrate: 130),
        .heartrate(seconds: 2052, heartrate: 135),
        .heartrate(seconds: 2057, heartrate: 140),
        .heartrate(seconds: 2062, heartrate: 145),
        .heartrate(seconds: 2067, heartrate: 150),
        .location(seconds: 2071, latitude: 49.7081834436317, longitude: 9.26154142954882),
        .heartrate(seconds: 2072, heartrate: 155),
        .heartrate(seconds: 2077, heartrate: 160),
        .heartrate(seconds: 2082, heartrate: 165),
        .heartrate(seconds: 2087, heartrate: 170),
        .heartrate(seconds: 2092, heartrate: 175),
        .heartrate(seconds: 2097, heartrate: 180),
        .location(seconds: 2101, latitude: 49.7083792107516, longitude: 9.26161927354216),
        .heartrate(seconds: 2102, heartrate: 185),
        .motion(seconds: 2099, idx: 2),
        .heartrate(seconds: 2107, heartrate: 180),
        .heartrate(seconds: 2112, heartrate: 175),
        .heartrate(seconds: 2117, heartrate: 170),
        .heartrate(seconds: 2122, heartrate: 165),
        .heartrate(seconds: 2127, heartrate: 160),
        .location(seconds: 2131, latitude: 49.708686843203, longitude: 9.26155007888141),
        .heartrate(seconds: 2132, heartrate: 155),
        .heartrate(seconds: 2137, heartrate: 150),
        .heartrate(seconds: 2142, heartrate: 145),
        .heartrate(seconds: 2147, heartrate: 140),
        .heartrate(seconds: 2152, heartrate: 135),
        .heartrate(seconds: 2157, heartrate: 130),
        .location(seconds: 2161, latitude: 49.709089559154, longitude: 9.26183550685064),
        .heartrate(seconds: 2162, heartrate: 125),
        .motion(seconds: 2159, idx: 1),
        .heartrate(seconds: 2167, heartrate: 120),
        .heartrate(seconds: 2172, heartrate: 115),
        .heartrate(seconds: 2177, heartrate: 110),
        .heartrate(seconds: 2182, heartrate: 105),
        .heartrate(seconds: 2187, heartrate: 100),
        .location(seconds: 2191, latitude: 49.7096432880663, longitude: 9.26192200017657),
        .heartrate(seconds: 2192, heartrate: 95),
        .heartrate(seconds: 2197, heartrate: 90),
        .heartrate(seconds: 2202, heartrate: 85),
        .heartrate(seconds: 2207, heartrate: 80),
        .heartrate(seconds: 2212, heartrate: 75),
        .heartrate(seconds: 2217, heartrate: 70),
        .location(seconds: 2221, latitude: 49.7104542937668, longitude: 9.26242366146697),
        .heartrate(seconds: 2222, heartrate: 65),
        .motion(seconds: 2219, idx: 0),
        .heartrate(seconds: 2227, heartrate: 60),
        .heartrate(seconds: 2232, heartrate: 55),
        .heartrate(seconds: 2237, heartrate: 50),
        .heartrate(seconds: 2242, heartrate: 45),
        .heartrate(seconds: 2247, heartrate: 50),
        .location(seconds: 2251, latitude: 49.7118525476946, longitude: 9.26269179077325),
        .heartrate(seconds: 2252, heartrate: 55),
        .heartrate(seconds: 2257, heartrate: 60),
        .heartrate(seconds: 2262, heartrate: 65),
        .heartrate(seconds: 2267, heartrate: 70),
        .heartrate(seconds: 2272, heartrate: 75),
        .heartrate(seconds: 2277, heartrate: 80),
        .location(seconds: 2281, latitude: 49.7118805123618, longitude: 9.26310695873772),
        .heartrate(seconds: 2282, heartrate: 85),
        .motion(seconds: 2279, idx: 1),
        .heartrate(seconds: 2287, heartrate: 90),
        .heartrate(seconds: 2292, heartrate: 95),
        .heartrate(seconds: 2297, heartrate: 100),
        .heartrate(seconds: 2302, heartrate: 105),
        .heartrate(seconds: 2307, heartrate: 110),
        .location(seconds: 2311, latitude: 49.7118301759492, longitude: 9.26410163198593),
        .heartrate(seconds: 2312, heartrate: 115),
        .heartrate(seconds: 2317, heartrate: 120),
        .heartrate(seconds: 2322, heartrate: 125),
        .heartrate(seconds: 2327, heartrate: 130),
        .heartrate(seconds: 2332, heartrate: 135),
        .heartrate(seconds: 2337, heartrate: 140),
        .location(seconds: 2341, latitude: 49.7119196628689, longitude: 9.26494926658005),
        .heartrate(seconds: 2342, heartrate: 145),
        .motion(seconds: 2339, idx: 2),
        .heartrate(seconds: 2347, heartrate: 150),
        .heartrate(seconds: 2352, heartrate: 155),
        .heartrate(seconds: 2357, heartrate: 160),
        .heartrate(seconds: 2362, heartrate: 165),
        .heartrate(seconds: 2367, heartrate: 170),
        .location(seconds: 2371, latitude: 49.7120930433067, longitude: 9.26500981190821),
        .heartrate(seconds: 2372, heartrate: 175),
        .heartrate(seconds: 2377, heartrate: 180),
        .heartrate(seconds: 2382, heartrate: 185),
        .heartrate(seconds: 2387, heartrate: 180),
        .heartrate(seconds: 2392, heartrate: 175),
        .heartrate(seconds: 2397, heartrate: 170),
        .location(seconds: 2401, latitude: 49.7121601581487, longitude: 9.26567581051788),
        .heartrate(seconds: 2402, heartrate: 165),
        .motion(seconds: 2399, idx: 3),
        .heartrate(seconds: 2407, heartrate: 160),
        .heartrate(seconds: 2412, heartrate: 155),
        .heartrate(seconds: 2417, heartrate: 150),
        .heartrate(seconds: 2422, heartrate: 145),
        .heartrate(seconds: 2427, heartrate: 140),
        .location(seconds: 2431, latitude: 49.7136198830428, longitude: 9.26679157440474),
        .heartrate(seconds: 2432, heartrate: 135),
        .heartrate(seconds: 2437, heartrate: 130),
        .heartrate(seconds: 2442, heartrate: 125),
        .heartrate(seconds: 2447, heartrate: 120),
        .heartrate(seconds: 2452, heartrate: 115),
        .heartrate(seconds: 2457, heartrate: 110),
        .location(seconds: 2461, latitude: 49.7134912500469, longitude: 9.26718944370402),
        .heartrate(seconds: 2462, heartrate: 105),
        .motion(seconds: 2459, idx: 2),
        .heartrate(seconds: 2467, heartrate: 100),
        .heartrate(seconds: 2472, heartrate: 95),
        .heartrate(seconds: 2477, heartrate: 90),
        .heartrate(seconds: 2482, heartrate: 85),
        .heartrate(seconds: 2487, heartrate: 80),
        .location(seconds: 2491, latitude: 49.7137988501224, longitude: 9.26744027434922),
        .heartrate(seconds: 2492, heartrate: 75),
        .heartrate(seconds: 2497, heartrate: 70),
        .heartrate(seconds: 2502, heartrate: 65),
        .heartrate(seconds: 2507, heartrate: 60),
        .heartrate(seconds: 2512, heartrate: 55),
        .heartrate(seconds: 2517, heartrate: 50),
        .location(seconds: 2521, latitude: 49.7134912500469, longitude: 9.26838305160187),
        .heartrate(seconds: 2522, heartrate: 45),
        .motion(seconds: 2519, idx: 1),
        .heartrate(seconds: 2527, heartrate: 50),
        .heartrate(seconds: 2532, heartrate: 55),
        .heartrate(seconds: 2537, heartrate: 60),
        .heartrate(seconds: 2542, heartrate: 65),
        .heartrate(seconds: 2547, heartrate: 70),
        .location(seconds: 2551, latitude: 49.7140840775425, longitude: 9.26893660888783),
        .heartrate(seconds: 2552, heartrate: 75),
        .heartrate(seconds: 2557, heartrate: 80),
        .heartrate(seconds: 2562, heartrate: 85),
        .heartrate(seconds: 2567, heartrate: 90),
        .heartrate(seconds: 2572, heartrate: 95),
        .heartrate(seconds: 2577, heartrate: 100),
        .location(seconds: 2581, latitude: 49.7141511896332, longitude: 9.26907499820932),
        .heartrate(seconds: 2582, heartrate: 105),
        .motion(seconds: 2579, idx: 0),
        .heartrate(seconds: 2587, heartrate: 110),
        .heartrate(seconds: 2592, heartrate: 115),
        .heartrate(seconds: 2597, heartrate: 120),
        .heartrate(seconds: 2602, heartrate: 125),
        .heartrate(seconds: 2607, heartrate: 130),
        .location(seconds: 2611, latitude: 49.7146545273861, longitude: 9.26898850487916),
        .heartrate(seconds: 2612, heartrate: 135),
        .heartrate(seconds: 2617, heartrate: 140),
        .heartrate(seconds: 2622, heartrate: 145),
        .heartrate(seconds: 2627, heartrate: 150),
        .heartrate(seconds: 2632, heartrate: 155),
        .heartrate(seconds: 2637, heartrate: 160),
        .location(seconds: 2641, latitude: 49.714464378177, longitude: 9.2699658794455),
        .heartrate(seconds: 2642, heartrate: 165),
        .motion(seconds: 2639, idx: 1),
        .heartrate(seconds: 2647, heartrate: 170),
        .heartrate(seconds: 2652, heartrate: 175),
        .heartrate(seconds: 2657, heartrate: 180),
        .heartrate(seconds: 2662, heartrate: 185),
        .heartrate(seconds: 2667, heartrate: 180),
        .location(seconds: 2671, latitude: 49.7141064482631, longitude: 9.27120273400632),
        .heartrate(seconds: 2672, heartrate: 175)
    ]
    
    struct MA: MotionActivityProtocol {
        static var canUse: Bool = true
        
        init(
            startDate: Date,
            stationary: Bool,
            walking: Bool,
            running: Bool,
            cycling: Bool,
            confidence: CMMotionActivityConfidence)
        {
            self.startDate = startDate
            self.stationary = stationary
            self.walking = walking
            self.running = running
            self.cycling = cycling
            self.confidence = confidence
        }
        
        init(startDate: Date, ma: MA) {
            self.startDate = startDate
            self.stationary = ma.stationary
            self.walking = ma.walking
            self.running = ma.running
            self.cycling = ma.cycling
            self.confidence = ma.confidence
        }
        
        let startDate: Date
        let stationary: Bool
        let walking: Bool
        let running: Bool
        let cycling: Bool
        let confidence: CMMotionActivityConfidence
    }

    let motions = [
        MA( startDate: Date(),
            stationary: true,
            walking: false,
            running: false,
            cycling: false,
            confidence: .high),
        MA( startDate: Date(),
            stationary: false,
            walking: true,
            running: false,
            cycling: false,
            confidence: .high),
        MA( startDate: Date(),
            stationary: false,
            walking: false,
            running: true,
            cycling: false,
            confidence: .high),
        MA( startDate: Date(),
            stationary: false,
            walking: false,
            running: false,
            cycling: true,
            confidence: .high)
    ]
    
    // Locations are injected every 30 seconds
    // HR changes every second by 2. Starting at lower limit, up to upper limit and then -2 back.
    // Activities are created round robin every 5 minutes changing. Starting with paused. They come in a second delayed

    // MARK: - Simulate
    
    class BP: BleProducerProtocol {
        static let sharedInstance: BleProducerProtocol = BP()
        static var working: Bool = true

        private var config: BleProducer.Config?
        private let uuid = UUID()
        
        fileprivate func inject(heartrate: Int, at: Date) {
            guard BP.working else {return}
            config?.readers[CBUUID(string: "2A37")]?(uuid, Data([UInt8(0x00), UInt8(heartrate)]), at)
        }

        func start(config: BleProducer.Config, asOf: Date, transientFailedPeripheralUuid: UUID?) {
            self.config = config
            config.status(BP.working ? .started(asOf: asOf) : .notAuthorized(asOf: asOf))
        }

        func stop() {config?.status(.stopped)}
        func pause() {config?.status(.paused)}
        func resume() {config?.status(.resumed)}

        func readValue(_ peripheralUuid: UUID, _ characteristicUuid: CBUUID) {}
        func writeValue(_ peripheralUuid: UUID, _ characteristicUuid: CBUUID, _ data: Data) {}
        func setNotifyValue(_ peripheralUuid: UUID, _ characteristicUuid: CBUUID, _ notify: Bool) {}
    }
    
    class AP: AclProducerProtocol {
        static let sharedInstance: AclProducerProtocol = AP()
        static var working: Bool = true

        private var value: ((MotionActivityProtocol) -> Void)?
        private var status: ((AclProducer.Status) -> Void)?

        fileprivate func inject(_ motion: MotionActivityProtocol) {
            if AP.working {value?(motion)}
        }
        
        func start(
            value: @escaping (MotionActivityProtocol) -> Void,
            status: @escaping (AclProducer.Status) -> Void,
            asOf: Date)
        {
            self.value = value
            self.status = status
            status(AP.working ? .started(asOf: asOf) : .notAuthorized(asOf: asOf))
        }
        
        func stop() {status?(.stopped)}
        func pause() {status?(.paused)}
        func resume() {status?(.resumed)}
    }
    
    class GP: GpsProducerProtocol {
        static let sharedInstance: GpsProducerProtocol = GP()
        static var working: Bool = true

        private var value: ((CLLocation) -> Void)?
        private var status: ((GpsProducer.Status) -> Void)?
        
        fileprivate func inject(_ location: CLLocation) {if GP.working {value?(location)}}
        
        func start(
            value: @escaping (CLLocation) -> Void,
            status: @escaping (GpsProducer.Status) -> Void,
            asOf: Date)
        {
            self.value = value
            self.status = status
            status(GP.working ? .started(asOf: asOf) : .notAuthorized(asOf: asOf))
        }
        
        func stop() {status?(.stopped)}
        func pause() {status?(.paused)}
        func resume() {status?(.resumed)}
    }
    
    private func loop(
        aclProducer: AclProducerProtocol,
        bleProducer: BleProducerProtocol,
        gpsProducer: GpsProducerProtocol,
        work: (TimeInterval) throws -> Void) rethrows
    {
        // Start the engine
        ProfileService.sharedInstance.onAppear()
        ProfileService.sharedInstance.hrMax.onChange(to: 181)
        ProfileService.sharedInstance.hrResting.onChange(to: 40)
    
        try work(Date.distantPast.timeIntervalSince1970)

        RunService.sharedInstance.start(
            producer: RunService.Producer(
                aclProducer: aclProducer,
                bleProducer: bleProducer,
                gpsProducer: gpsProducer),
                asOf: Date(timeIntervalSince1970: 0))
        try work(0)

        // loop through actions
        for action in actions {
            switch action {
            case .location(let seconds, let latitude, let longitude):
                let location = CLLocation(
                    coordinate: CLLocationCoordinate2D(
                        latitude: latitude,
                        longitude: longitude),
                    altitude: 0,
                    horizontalAccuracy: 0,
                    verticalAccuracy: 0,
                    timestamp: Date(timeIntervalSince1970: seconds))
                (GP.sharedInstance as! GP).inject(location)
                try work(seconds)
            case .heartrate(let seconds, let heartrate):
                (BP.sharedInstance as! BP)
                    .inject(heartrate: heartrate, at: Date(timeIntervalSince1970: seconds))
                try work(seconds)
            case .motion(let seconds, let idx):
                (AP.sharedInstance as! AP).inject(
                    MA( startDate: Date(timeIntervalSince1970: seconds), ma: motions[idx]))
                try work(seconds)
            }
        }
        
        // The end
        RunService.sharedInstance.stop()
        try work(Date.distantFuture.timeIntervalSince1970)
    }
    
    // MARK: - Collect & Compare Testdata
        
    private struct TestData: Codable {
        let asOf: TimeInterval
        let currents: CurrentsTestData
        let totals: [TotalsTestData]
        let sumTotals: TotalsTestData
    }
    
    private struct CurrentsTestData: Codable {
        let heartrate: Int
        let intensity: Intensity
        let type: IsActiveProducer.ActivityType
        let speed: CLLocationSpeed
        let aclStatus: String
        let bleStatus: String
        let gpsStatus: String
    }
    
    private struct TotalsTestData: Codable {
        let intensity: Intensity
        let type: IsActiveProducer.ActivityType
        let distanceM: CLLocationDistance
        let durationSec: TimeInterval
        let paceSecPerKm: TimeInterval
        let heartrateBpm: Int
        let vdot: Double
    }

    private var testData = [TestData]()
    private var compareData = [Int: TestData]()
    
    private func collectTestData(asOf: TimeInterval) {
        print("--- \(asOf) ---", terminator: "")
        let currents = CurrentsService.sharedInstance
        let totals = TotalsService.sharedInstance.totals(upTo: Date(timeIntervalSince1970: asOf))
        let sumTotals = TotalsTestData(
            intensity: .Cold,
            type: .unknown,
            distanceM: totals.values.map {$0.distanceM}.reduce(0.0, {$0 + $1}),
            durationSec: totals.values.map {$0.durationSec}.reduce(0.0, {$0 + $1}),
            paceSecPerKm: .nan,
            heartrateBpm: -1,
            vdot: .nan)
        print(" \(currents.intensity.intensity), \(sumTotals.distanceM), \(sumTotals.durationSec)")
        
        testData.append(
            TestData(
                asOf: asOf,
                currents: CurrentsTestData(
                    heartrate: currents.heartrate.heartrate,
                    intensity: currents.intensity.intensity,
                    type: currents.isActive.type,
                    speed: currents.speed.speedMperSec,
                    aclStatus: "\(currents.aclStatus)",
                    bleStatus: "\(currents.bleStatus)",
                    gpsStatus: "\(currents.gpsStatus)"),
                totals: totals.values.map {
                    TotalsTestData(
                        intensity: $0.intensity,
                        type: $0.activityType,
                        distanceM: $0.distanceM,
                        durationSec: $0.durationSec,
                        paceSecPerKm: $0.paceSecPerKm,
                        heartrateBpm: $0.heartrateBpm,
                        vdot: $0.vdot)
                },
                sumTotals: sumTotals))
    }
    
    private func writeTestData(_ name: String) throws {
        print(FileHandling.write(testData, to: name)?.absoluteString ?? "*not saved*")
    }
    
    private func readTestData(_ name: String) throws {
        testData = FileHandling.read([TestData].self, from: name) ?? []
        testData.forEach {compareData[Int($0.asOf)] = $0}
    }
    
    private func compareTestData(asOf: TimeInterval) {
        guard let testData = compareData[Int(asOf)] else {
            XCTFail()
            return
        }
        
        let currents = CurrentsService.sharedInstance
        let totals = TotalsService.sharedInstance.totals(upTo: Date(timeIntervalSince1970: asOf))
        let sumTotals = TotalsTestData(
            intensity: .Cold,
            type: .unknown,
            distanceM: totals.values.map {$0.distanceM}.reduce(0.0, {$0 + $1}),
            durationSec: totals.values.map {$0.durationSec}.reduce(0.0, {$0 + $1}),
            paceSecPerKm: .nan,
            heartrateBpm: -1,
            vdot: .nan)

        // Compare Currents
        XCTAssertEqual(currents.heartrate.heartrate, testData.currents.heartrate, "\(asOf)")
        XCTAssertEqual(currents.intensity.intensity, testData.currents.intensity, "\(asOf)")
        XCTAssertEqual(currents.isActive.type, testData.currents.type, "\(asOf)")
        XCTAssertEqual(currents.speed.speedMperSec, testData.currents.speed, accuracy: 0.1, "\(asOf)")
        XCTAssertEqual("\(currents.aclStatus)", testData.currents.aclStatus, "\(asOf)")
        XCTAssertEqual("\(currents.bleStatus)", testData.currents.bleStatus, "\(asOf)")
        XCTAssertEqual("\(currents.gpsStatus)", testData.currents.gpsStatus, "\(asOf)")
        
        // Compare sum totals
        XCTAssertEqual(sumTotals.distanceM, testData.sumTotals.distanceM, accuracy: 0.1, "\(asOf)")
        XCTAssertEqual(sumTotals.durationSec, testData.sumTotals.durationSec, accuracy: 0.1, "\(asOf)")
        
        // Compare totals
        XCTAssertEqual(totals.count, testData.totals.count, "\(asOf)")
        XCTAssertEqual(
            totals.map {$0.value.intensity}.sorted(),
            testData.totals.map {$0.intensity}.sorted(), "\(asOf)")
        XCTAssertEqual(
            totals.map {$0.value.activityType.rawValue}.sorted(),
            testData.totals.map {$0.type.rawValue}.sorted(), "\(asOf)")
        XCTAssertEqualArray(
            totals.map {$0.value.distanceM}.sorted(),
            testData.totals.map {$0.distanceM}.sorted(),
            accuracy: 0.1, "\(asOf)")
        XCTAssertEqualArray(
            totals.map {$0.value.durationSec}.sorted(),
            testData.totals.map {$0.durationSec}.sorted(),
            accuracy: 0.1, "\(asOf)")
        XCTAssertEqual(
            totals.map {$0.value.heartrateBpm}.sorted(),
            testData.totals.map {$0.heartrateBpm}.sorted(), "\(asOf)")
    }
    
    private func collector(
        _ fileName: String,
        _ apWorking: Bool, _ bpWorking: Bool, _ gpWorking: Bool) throws
    {
        MA.canUse = apWorking
        AP.working = apWorking
        BP.working = bpWorking
        GP.working = gpWorking

        try loop(
            aclProducer: AP.sharedInstance,
            bleProducer: BP.sharedInstance,
            gpsProducer: GP.sharedInstance)
        {
            collectTestData(asOf: $0)
            
            if $0 == Date.distantFuture.timeIntervalSince1970 {
                print("--- DONE ---")
                try writeTestData("\(fileName).json")
            }
        }
    }
    
    private func comparer(
        _ fileName: String,
        _ apWorking: Bool, _ bpWorking: Bool, _ gpWorking: Bool) throws
    {
        MA.canUse = apWorking
        AP.working = apWorking
        BP.working = bpWorking
        GP.working = gpWorking

        try loop(
            aclProducer: AP.sharedInstance,
            bleProducer: BP.sharedInstance,
            gpsProducer: GP.sharedInstance)
        {
            if $0 == Date.distantPast.timeIntervalSince1970 {
                try readTestData("\(fileName)")
            } else {
                compareTestData(asOf: $0)
            }
        }
    }

    // MARK: - Tests Cases

    func testCollectNormalOperation() throws {try collector("normalOperation", true, true, true)}
    func testCompareNormalOperation() throws {try comparer("normalOperation", true, true, true)}
    
    func testCollectAclNotAllowed() throws {try collector("APNotAllowed", false, true, true)}
    func testCompareAclNotAllowed() throws {try comparer("APNotAllowed", false, true, true)}
    
    func testCollectBleNotAllowed() throws {try collector("BPNotAllowed", true, false, true)}
    func testCompareBleNotAllowed() throws {try comparer("BPNotAllowed", true, false, true)}
    
    func testCollectGpsNotAllowed() throws {try collector("GPNotAllowed", true, true, false)}
    func testCompareGpsNotAllowed() throws {try comparer("GPNotAllowed", true, true, false)}
    
    func testCollectAclOnlyAllowed() throws {try collector("APOnlyAllowed", true, false, false)}
    func testCompareAclOnlyAllowed() throws {try comparer("APOnlyAllowed", true, false, false)}
    
    func testCollectBleOnlyAllowed() throws {try collector("BPOnlyAllowed", false, true, false)}
    func testCompareBleOnlyAllowed() throws {try comparer("BPOnlyAllowed", false, true, false)}
    
    func testCollectGpsOnlyAllowed() throws {try collector("GPOnlyAllowed", false, false, true)}
    func testCompareGpsOnlyAllowed() throws {try comparer("GPOnlyAllowed", false, false, true)}

    func testHrGraphService() throws {
        // Collects hr as a graph, the totals of avg-hr per intensity, up to date and can read/write on disk
        // Data is collected from RunService, ble-producer and derived intensity-producer
        ProfileService.sharedInstance.onAppear()
        ProfileService.sharedInstance.hrMax.onChange(to: 181)
        ProfileService.sharedInstance.hrResting.onChange(to: 40)
        ProfileService.sharedInstance.hrLimits.onAppear()
        print(ProfileService.sharedInstance.hrLimits.value)

        // Must access elements to ensure, they're created
        print(HrGraphService.sharedInstance.graph.isEmpty)
        print(HrGraphService.sharedInstance.hrSecs.isEmpty)

        RunService.sharedInstance.start(
            producer: RunService.Producer(
                aclProducer: AP.sharedInstance,
                bleProducer: BP.sharedInstance,
                gpsProducer: GP.sharedInstance),
            asOf: Date(timeIntervalSince1970: 0))
        
        XCTAssertTrue(HrGraphService.sharedInstance.graph.isEmpty)
        XCTAssertTrue(HrGraphService.sharedInstance.hrSecs.isEmpty)

        (BP.sharedInstance as! BP).inject(heartrate: 0x30, at: Date(timeIntervalSince1970: 100))
        (BP.sharedInstance as! BP).inject(heartrate: 0x40, at: Date(timeIntervalSince1970: 200))
        (BP.sharedInstance as! BP).inject(heartrate: 0xA0, at: Date(timeIntervalSince1970: 300))
        (BP.sharedInstance as! BP).inject(heartrate: 0xF0, at: Date(timeIntervalSince1970: 400))
        (BP.sharedInstance as! BP).inject(heartrate: 0xA0, at: Date(timeIntervalSince1970: 500))

        XCTAssertEqual(
            HrGraphService.sharedInstance.graph.compactMap {$0.heartrate},
            [48, 64, 160, 240, 240, 160])
        XCTAssertEqual(
            HrGraphService.sharedInstance.graph.compactMap {$0.intensity},
            [.Cold, .Marathon, .Marathon, .Repetition, .Marathon, .Marathon])
        
        XCTAssertEqual(HrGraphService.sharedInstance.hrSecs.count, 3)
        XCTAssertNotNil(HrGraphService.sharedInstance.hrSecs[.Cold])
        XCTAssertNotNil(HrGraphService.sharedInstance.hrSecs[.Marathon])
        XCTAssertNotNil(HrGraphService.sharedInstance.hrSecs[.Repetition])
        
        // Up to date
        var x1 = HrGraphService.sharedInstance.hrSecs(upTo: Date(timeIntervalSince1970: 1000))
        x1[.Marathon] = HrGraphService.HrTotal(
            duration: (x1[.Marathon]?.duration ?? 0) + 10,
            sumHeartrate: (x1[.Marathon]?.sumHeartrate ?? 0) + 1600)
        let x2 = HrGraphService.sharedInstance.hrSecs(upTo: Date(timeIntervalSince1970: 1010))
        XCTAssertEqual(x1.count, x2.count)
        XCTAssertEqual(x1.map {$0.value.sumHeartrate}.sorted(), x2.map {$0.value.sumHeartrate}.sorted())
        XCTAssertEqual(x1.map {$0.value.duration}.sorted(), x2.map {$0.value.duration}.sorted())
        
        // Does read/write work?
        RunService.sharedInstance.pause() // save
        
        let x3 = HrGraphService.sharedInstance.graph
        (BP.sharedInstance as! BP).inject(heartrate: 0x30, at: Date(timeIntervalSince1970: 2000))
        XCTAssertNotEqual(x3.count, HrGraphService.sharedInstance.graph.count) // changed
        
        RunService.sharedInstance.resume() // restore
        XCTAssertEqual(
            HrGraphService.sharedInstance.graph.compactMap {$0.heartrate},
            [48, 64, 160, 240, 240, 160])
        XCTAssertEqual(
            HrGraphService.sharedInstance.graph.compactMap {$0.intensity},
            [.Cold, .Marathon, .Marathon, .Repetition, .Marathon, .Marathon])
    }
    
    func testPathService0() throws {
        // Is expected to produce a path, where each element contains all locations, an avg-location and a flag to indicate activity
        // Ranges must be without gaps or overlaps from -inf to +inf. Some elements empty/without locations
        
        // Must access elements to ensure, they're created
        print(PathService.sharedInstance.path.isEmpty)
        
        RunService.sharedInstance.start(
            producer: RunService.Producer(
                aclProducer: AP.sharedInstance,
                bleProducer: BP.sharedInstance,
                gpsProducer: GP.sharedInstance),
            asOf: Date(timeIntervalSince1970: 0))
        XCTAssertEqual(PathService.sharedInstance.path.first?.range, .distantPast ..< .distantFuture)

        // Collect results
        (GP.sharedInstance as! GP).inject(CLLocation(
            coordinate: CLLocationCoordinate2D(
                latitude: 1,
                longitude: 1),
            altitude: 0,
            horizontalAccuracy: 0,
            verticalAccuracy: 0,
            timestamp: Date(timeIntervalSince1970: 500)))
        (GP.sharedInstance as! GP).inject(CLLocation(
            coordinate: CLLocationCoordinate2D(
                latitude: 2,
                longitude: 2),
            altitude: 0,
            horizontalAccuracy: 0,
            verticalAccuracy: 0,
            timestamp: Date(timeIntervalSince1970: 1500)))
        (GP.sharedInstance as! GP).inject(CLLocation(
            coordinate: CLLocationCoordinate2D(
                latitude: 3,
                longitude: 3),
            altitude: 0,
            horizontalAccuracy: 0,
            verticalAccuracy: 0,
            timestamp: Date(timeIntervalSince1970: 1700)))
        (GP.sharedInstance as! GP).inject(CLLocation(
            coordinate: CLLocationCoordinate2D(
                latitude: 4,
                longitude: 4),
            altitude: 0,
            horizontalAccuracy: 0,
            verticalAccuracy: 0,
            timestamp: Date(timeIntervalSince1970: 2000)))
        (GP.sharedInstance as! GP).inject(CLLocation(
            coordinate: CLLocationCoordinate2D(
                latitude: 5,
                longitude: 5),
            altitude: 0,
            horizontalAccuracy: 0,
            verticalAccuracy: 0,
            timestamp: Date(timeIntervalSince1970: 2500)))
        XCTAssertEqual(PathService.sharedInstance.path.map {$0.range}, [
            .distantPast ..< .distantFuture
        ])
        XCTAssertEqual(
            PathService.sharedInstance.path.compactMap {$0.isActive?.isActive},
            [false])
        XCTAssertEqual(
            PathService.sharedInstance.path.map {$0.locations.count},
            [5])

        (AP.sharedInstance as! AP).inject(MA(
            startDate: Date(timeIntervalSince1970: 1000),
            stationary: false, walking: false, running: true, cycling: false,
            confidence: .high))
        (AP.sharedInstance as! AP).inject(MA(
            startDate: Date(timeIntervalSince1970: 2000),
            stationary: true, walking: false, running: false, cycling: false,
            confidence: .high))
        XCTAssertEqual(PathService.sharedInstance.path.map {$0.range}, [
            .distantPast ..< Date(timeIntervalSince1970: 1000),
            Date(timeIntervalSince1970: 1000) ..< Date(timeIntervalSince1970: 2000),
            Date(timeIntervalSince1970: 2000) ..< .distantFuture
        ])
        XCTAssertEqual(
            PathService.sharedInstance.path.compactMap {$0.isActive?.isActive},
            [false, true, false])
        XCTAssertEqual(
            PathService.sharedInstance.path.map {$0.locations.count},
            [1,2,2])

        (AP.sharedInstance as! AP).inject(MA(
            startDate: Date(timeIntervalSince1970: 2200),
            stationary: false, walking: false, running: true, cycling: false,
            confidence: .high))
        (AP.sharedInstance as! AP).inject(MA(
            startDate: Date(timeIntervalSince1970: 2700),
            stationary: true, walking: false, running: false, cycling: false,
            confidence: .high))
        XCTAssertEqual(PathService.sharedInstance.path.map {$0.range}, [
            .distantPast ..< Date(timeIntervalSince1970: 1000),
            Date(timeIntervalSince1970: 1000) ..< Date(timeIntervalSince1970: 2000),
            Date(timeIntervalSince1970: 2000) ..< Date(timeIntervalSince1970: 2200),
            Date(timeIntervalSince1970: 2200) ..< Date(timeIntervalSince1970: 2700),
            Date(timeIntervalSince1970: 2700) ..< .distantFuture
        ])
        XCTAssertEqual(
            PathService.sharedInstance.path.compactMap {$0.isActive?.isActive},
            [false, true, false, true, false])
        XCTAssertEqual(
            PathService.sharedInstance.path.map {$0.locations.count},
            [1,2,1,1,0])
        
        let p1 = PathService.sharedInstance.path[1]
        XCTAssertEqual(p1.avgLocation?.coordinate.latitude, 2.5)
        XCTAssertEqual(p1.avgLocation?.coordinate.longitude, 2.5)
        
        // Does read/write work?
        RunService.sharedInstance.pause()
        let x3 = PathService.sharedInstance.path
        (GP.sharedInstance as! GP).inject(CLLocation(
            coordinate: CLLocationCoordinate2D(
                latitude: 5,
                longitude: 5),
            altitude: 0,
            horizontalAccuracy: 0,
            verticalAccuracy: 0,
            timestamp: Date(timeIntervalSince1970: 3000)))
        (GP.sharedInstance as! GP).inject(CLLocation(
            coordinate: CLLocationCoordinate2D(
                latitude: 5,
                longitude: 5),
            altitude: 0,
            horizontalAccuracy: 0,
            verticalAccuracy: 0,
            timestamp: Date(timeIntervalSince1970: 3500)))
        XCTAssertNotEqual(
            x3.map {$0.locations.count},
            PathService.sharedInstance.path.map {$0.locations.count})
        RunService.sharedInstance.resume()
        XCTAssertEqual(
            PathService.sharedInstance.path.compactMap {$0.isActive?.isActive},
            [false, true, false, true, false])
        XCTAssertEqual(
            x3.map {$0.locations.count},
            PathService.sharedInstance.path.map {$0.locations.count})
    }
    
    private func XCTAssertEqualArray(_ x1: [Double], _ x2: [Double], accuracy: Double, _ msg: String) {
        guard x1.count == x2.count else {
            XCTAssertEqual(x1.count, x2.count, msg)
            return
        }
        
        for i in x1.indices {
            XCTAssertEqual(x1[i], x2[i], accuracy: accuracy, msg)
        }
    }
}
