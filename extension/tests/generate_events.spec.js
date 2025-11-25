// Smoke tests: basic normalization behavior for minimal raw payloads
import { expect } from "chai";
import * as gen from "../src/ics-generator.js";

describe("Generate events", () => {
  it("Normalizes a simple raw payload", () => {
    const raw = {
      Terms: [
        {
          Code: "202509",
          Name: "Fall 2025",
          PlannedCourses: [
            {
              Section: {
                CourseName: "MATH101",
                Number: "001",
                MinimumCredits: 0.5,
                Faculty: ["Prof A"],
                PlannedMeetings: [
                  {
                    InstructionalMethod: "LEC",
                    StartTime: "9:00 AM",
                    EndTime: "10:20 AM",
                    DaysOfWeek: "MW",
                    MeetingLocation: "Room 100",
                    StartDateString: "09/02/2025",
                    EndDateString: "11/27/2025",
                    StartDate: "09/02/2025",
                    EndDate: "11/27/2025",
                  },
                ],
              },
            },
          ],
        },
      ],
    };

    const events = gen.generateEventsFromRawData(raw, ["202509"]);
    expect(events).to.be.an("array").with.lengthOf(1);
    expect(events[0].CourseName).to.equal("MATH101");

    const ics = gen.generateICSFromRawData(raw, ["202509"]);
    expect(ics).to.be.a("string");
    expect(ics).to.include("BEGIN:VCALENDAR");
  });
});
