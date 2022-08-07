`timescale 1ns / 1ps

module device(clock, P, M, equal, num1, anode, SSD, LED);
    input clock, P, M, equal;
    input [3:0] num1;
    reg [3:0] count = 4'd0;
    reg [95:0] id1 = "123456789", id2 = "0101010101010"; //set the rolling character numbers
    reg [1:0] m_tmp = 2'b00;
    reg [95:0] id, tmp;
    reg [31:0] roll;
    reg [3:0] sum, num1_tmp, num2, num3, SSD_temp;
    reg [3:0] curr_state, next_state;
    reg [27:0] counter1 = 28'd0, counter2 = 28'd0;
    reg clock_en;
    wire clock_counter, clock_multiplex;
    parameter f1 = 100000000; //1hz
    parameter f2 = 200000; //4khz
    output reg [3:0] anode;
    output reg [6:0] SSD;
    output reg LED;
    
    parameter state0 = 4'b0000;//fsm
    parameter state1 = 4'b0001;
    parameter state2 = 4'b0010;
    parameter state3 = 4'b0011;
    parameter state4 = 4'b0100;
    parameter state5 = 4'b0101;
    parameter state6 = 4'b0110;
    
    initial curr_state = state0;//clock divider
    always @(posedge clock) begin
        if (counter1 >= (f1 - 1)) counter1 <= 28'd0;
        else counter1 <= counter1 + 1;
        if (counter2 >= (f2 - 1)) counter2 <= 28'd0;
        else counter2 <= counter2 + 1;
    end
    assign clock_counter = (counter1 == 0);
    assign clock_multiplex = (counter2 == 0);
    
    always @ (posedge clock) begin//fsm
        curr_state <= next_state;
    end
    
    always @ (curr_state or equal or M or P) begin
        case (curr_state)
            state0: next_state <= state1;
            state1: if (M == 0) next_state <= state2; 
                    else if (M == 1) next_state <= state5; 
                    else next_state <= state0;
            state2: next_state <= state3;
            state3: next_state <= state4;
            state4: if (M == 1) next_state <= state1;
                    else next_state <= state3; 
            state5: if (M == 0) next_state <= state1; 
                    else if (equal == 0) next_state <= state5; 
                    else if (equal == 1) next_state <= state6;
                    else next_state <= state0;
            state6: if (M == 0) next_state <= state1; 
                    else if (equal == 0) next_state <= state5; 
                    else if (equal == 1) next_state <= state6;
                    else next_state <= state0;
            
            default: next_state <= state0; 
        endcase
    end//state machine
    
    always @ (curr_state or equal or M or P) begin//state machine output for each state
        case (curr_state)
            state0: begin LED <= 0; clock_en <= 0; end
            state1: begin sum <= 4'd0; num3 <= 4'd0; LED <= 0; clock_en <= 0; end
            state2: id <= P ? id2 : id1;
            state3: id <= id;
            state4: begin tmp = P ? id2 : id1;                        
                        if (id != tmp) begin
                            clock_en <= 0;
                            if (count == 0) id <= tmp;
                        end 
                        else begin
                            roll = id[103-(count*8) -: 32];
                            clock_en = 1;
                        end
                    end
            state5: begin num3 = sum; num1_tmp = num1; num2 = sum; end
            state6: begin sum = num1_tmp + num2;
                        LED = ((sum[3] != num2[3]) && (num1_tmp[3] == num2[3])); //overflow
                        if (sum[3] == 1) num3 <= ~sum + 1'b1;
                        else num3 <= sum;
                    end
        endcase
    end
    
    always @(posedge clock_counter) begin//function of rolling timing
        if (M) count <= 1;
        else if (clock_en == 0) count <= 1;
        else if (count == 9) count <= 0;
        else if (clock_en) count = count + 1;
    end
    
    always @(posedge clock_multiplex) begin//multiplex
        if (curr_state == state0 || curr_state == state1) anode <= 4'b1111;
        if (M == 0) begin
            case (m_tmp)
                2'b00: begin SSD_temp <= (roll[7:0] - 6'd48); anode <= 4'b1110; end
                2'b01: begin SSD_temp <= (roll[15:8] - 6'd48); anode <= 4'b1101; end
                2'b10: begin SSD_temp <= (roll[23:16] - 6'd48); anode <= 4'b1011; end
                2'b11: begin SSD_temp <= (roll[31:24] - 6'd48); anode <= 4'b0111; end
                default: anode <= 4'b1111;
            endcase
            end
        else begin
            if (sum[3] == 1) begin
                case (m_tmp)
                    2'b00: begin SSD_temp <= num3; anode <= 4'b1110; end
                    2'b01: begin SSD_temp <= 4'b1010; anode <= 4'b1101; end
                    default: anode <= 4'b1111;
                endcase end
            else begin SSD_temp <= num3; anode <= 4'b1110; end
            end
        m_tmp = m_tmp + 1;
    end
    

    always @(*) begin //ssd
        case(SSD_temp)
        4'b0000: SSD = 7'b0000001;
        4'b0001: SSD = 7'b1001111;
        4'b0010: SSD = 7'b0010010;
        4'b0011: SSD = 7'b0000110;
        4'b0100: SSD = 7'b1001100;
        4'b0101: SSD = 7'b0100100;
        4'b0110: SSD = 7'b0100000;
        4'b0111: SSD = 7'b0001111;
        4'b1000: SSD = 7'b0000000; 
        4'b1001: SSD = 7'b0000100;
        4'b1010: SSD = 7'b1111110;
        default: SSD = 7'b1111110;
        endcase
    end
endmodule