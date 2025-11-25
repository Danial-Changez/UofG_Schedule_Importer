// Unit tests for the ICS generator helpers (events normalization and ICS formatting)
import { expect } from "chai";
import * as gen from "../src/ics-generator.js";

describe("ICS-Generator Helpers", () => {
  it("eventsToICS accepts normalized events", () => {
    const events = [
      {
        CourseName: "X*1000",
        SectionNumber: "001",
        Credits: 0.5,
        Instructors: ["A B"],
        InstructionalMethod: "LEC",
        StartTime: "9:00 AM",
        EndTime: "10:00 AM",
        DaysOfWeek: "MW",
        Location: "Room",
        StartDate: "09/01/2025",
        EndDate: "12/01/2025",
      },
    ];

    const ics = gen.eventsToICS(events);
    expect(ics).to.be.a("string");
    expect(ics).to.include("BEGIN:VCALENDAR");
    expect(ics).to.include("SUMMARY:LEC X*1000*001");
  });

  it("generateEventsFromRawData filters by term codes", () => {
    const raw = {
      Terms: [
        { Code: "T1", PlannedCourses: [] },
        { Code: "T2", PlannedCourses: [] },
      ],
    };
    const res = gen.generateEventsFromRawData(raw, ["T2"]);
    expect(res).to.be.an("array");
    expect(res.length).to.equal(0);
  });
});
