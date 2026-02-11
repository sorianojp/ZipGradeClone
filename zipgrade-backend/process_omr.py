import cv2
import numpy as np
import sys
import json
import os

def order_points(pts):
    # initialzie a list of coordinates that will be ordered
    # such that the first entry in the list is the top-left,
    # the second entry is the top-right, the third is the
    # bottom-right, and the fourth is the bottom-left
    rect = np.zeros((4, 2), dtype = "float32")
    # the top-left point will have the smallest sum, whereas
    # the bottom-right point will have the largest sum
    s = pts.sum(axis = 1)
    rect[0] = pts[np.argmin(s)]
    rect[2] = pts[np.argmax(s)]
    # now, compute the difference between the points, the
    # top-right point will have the smallest difference,
    # whereas the bottom-left will have the largest difference
    diff = np.diff(pts, axis = 1)
    rect[1] = pts[np.argmin(diff)]
    rect[3] = pts[np.argmax(diff)]
    # return the ordered coordinates
    return rect

def four_point_transform(image, pts):
    # obtain a consistent order of the points and unpack them
    # individually
    rect = order_points(pts)
    (tl, tr, br, bl) = rect
    # compute the width of the new image, which will be the
    # maximum distance between bottom-right and bottom-left
    # x-coordiates or the top-right and top-left x-coordinates
    widthA = np.sqrt(((br[0] - bl[0]) ** 2) + ((br[1] - bl[1]) ** 2))
    widthB = np.sqrt(((tr[0] - tl[0]) ** 2) + ((tr[1] - tl[1]) ** 2))
    maxWidth = max(int(widthA), int(widthB))
    # compute the height of the new image, which will be the
    # maximum distance between the top-right and bottom-right
    # y-coordinates or the top-left and bottom-left y-coordinates
    heightA = np.sqrt(((tr[0] - br[0]) ** 2) + ((tr[1] - br[1]) ** 2))
    heightB = np.sqrt(((tl[0] - bl[0]) ** 2) + ((tl[1] - bl[1]) ** 2))
    maxHeight = max(int(heightA), int(heightB))
    # now that we have the dimensions of the new image, construct
    # the set of destination points to obtain a "birds eye view",
    # (i.e. top-down view) of the image, again specifying points
    # in the top-left, top-right, bottom-right, and bottom-left
    # order
    dst = np.array([
        [0, 0],
        [maxWidth - 1, 0],
        [maxWidth - 1, maxHeight - 1],
        [0, maxHeight - 1]], dtype = "float32")
    # compute the perspective transform matrix and then apply it
    M = cv2.getPerspectiveTransform(rect, dst)
    warped = cv2.warpPerspective(image, M, (maxWidth, maxHeight))
    # return the warped image
    return warped

def sort_contours(cnts, method="top-to-bottom"):
    # initialize the reverse flag and sort index
    reverse = False
    i = 0
    # handle if we need to sort in reverse
    if method == "right-to-left" or method == "bottom-to-top":
        reverse = True
    # handle if we are sorting against the y-coordinate rather than
    # the x-coordinate of the bounding box
    if method == "top-to-bottom" or method == "bottom-to-top":
        i = 1
    # construct the list of bounding boxes and sort them from top to
    # bottom
    boundingBoxes = [cv2.boundingRect(c) for c in cnts]
    (cnts, boundingBoxes) = zip(*sorted(zip(cnts, boundingBoxes),
        key=lambda b:b[1][i], reverse=reverse))
    # return the list of sorted contours and bounding boxes
    return (cnts, boundingBoxes)

def process_omr(image_path, num_questions=20):
    try:
        # Load image
        image = cv2.imread(image_path)
        if image is None:
            return {"error": "Failed to load image"}

        # Resize for consistent processing (optional but good for speed/constants)
        # image = cv2.resize(image, (800, 1000)) # Maintain aspect ratio ideally

        gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
        blurred = cv2.GaussianBlur(gray, (5, 5), 0)
        edged = cv2.Canny(blurred, 75, 200)

        # Find One Large Document Contour (The Paper/Sheet)
        cnts = cv2.findContours(edged.copy(), cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
        cnts = cnts[0] if len(cnts) == 2 else cnts[1]
        docCnt = None

        if len(cnts) > 0:
            cnts = sorted(cnts, key=cv2.contourArea, reverse=True)
            for c in cnts:
                peri = cv2.arcLength(c, True)
                approx = cv2.approxPolyDP(c, 0.02 * peri, True)
                if len(approx) == 4:
                    docCnt = approx
                    break
        
        # Apply Perspective Transform
        if docCnt is None:
             warped = gray
             output_img = image.copy() # Debug on original
        else:
            warped = four_point_transform(gray, docCnt.reshape(4, 2))
            output_img = four_point_transform(image, docCnt.reshape(4, 2))

        # Use Adaptive Thresholding (Better for lighting)
        thresh = cv2.adaptiveThreshold(warped, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
	                                   cv2.THRESH_BINARY_INV, 15, 2)

        # Find Bubbles
        cnts = cv2.findContours(thresh.copy(), cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
        cnts = cnts[0] if len(cnts) == 2 else cnts[1]
        questionCnts = []

        h_img, w_img = warped.shape
        # Relaxed Constraints
        min_dim = 15 # pixels
        max_dim = 100 # pixels
        
        for c in cnts:
            (x, y, w, h) = cv2.boundingRect(c)
            ar = w / float(h)
            if w >= min_dim and h >= min_dim and w <= max_dim and h <= max_dim and ar >= 0.7 and ar <= 1.3:
                questionCnts.append(c)

        # DEBUG: Draw detected bubbles
        cv2.drawContours(output_img, questionCnts, -1, (0, 0, 255), 2) # Red outlines

        if len(questionCnts) == 0:
             return {"error": "No answer bubbles detected. Try closer or better lighting."}

        # Sort contours
        (questionCnts, _) = sort_contours(questionCnts, method="top-to-bottom")

        # Split columns
        mid_x = w_img // 2
        left_cnts = []
        right_cnts = []
        for c in questionCnts:
            (x, y, w, h) = cv2.boundingRect(c)
            if x < mid_x:
                left_cnts.append(c)
            else:
                right_cnts.append(c)
        
        (left_cnts, _) = sort_contours(left_cnts, method="top-to-bottom") if len(left_cnts) > 0 else ([], [])
        (right_cnts, _) = sort_contours(right_cnts, method="top-to-bottom") if len(right_cnts) > 0 else ([], [])
        
        choices = ['A', 'B', 'C', 'D', 'E']
        real_results = []
        
        def process_column(cnts, start_q_num):
            current_q = start_q_num
            # We assume bubbles come in clean rows of 5.
            # If noise is detected, this breaks.
            # Robust Logic: Group by Y-coord using a threshold
            
            rows = []
            if not cnts: return

            # Simple grouping by Y
            cnts = sorted(cnts, key=lambda c: cv2.boundingRect(c)[1]) # Sort by Y
            
            current_row = [cnts[0]]
            last_y = cv2.boundingRect(cnts[0])[1]
            
            for i in range(1, len(cnts)):
                c = cnts[i]
                y = cv2.boundingRect(c)[1]
                if abs(y - last_y) < 20: # Same row threshold (20px)
                    current_row.append(c)
                else:
                    rows.append(current_row)
                    current_row = [c]
                    last_y = y
            rows.append(current_row) # Add last row

            for row in rows:
                if len(row) < 5: 
                    # Visual debug: draw yellow for skipped/incomplete rows
                    cv2.drawContours(output_img, row, -1, (0, 255, 255), 2)
                    continue 

                # Sort row L-R
                (row, _) = sort_contours(row, method="left-to-right")
                
                # Check top 5 only (in case noise added 6th bubble)
                row = row[:5]
                
                bubbled = None
                max_pixels = 0
                
                for (k, c) in enumerate(row):
                    mask = np.zeros(thresh.shape, dtype="uint8")
                    cv2.drawContours(mask, [c], -1, 255, -1)
                    mask = cv2.bitwise_and(thresh, thresh, mask=mask)
                    total = cv2.countNonZero(mask)
                    
                    # Highlight filled bubble logic
                    if total > max_pixels:
                        max_pixels = total
                        bubbled = k
                    
                    # Debug: Green text for total
                    # cv2.putText(output_img, str(total), (cv2.boundingRect(c)[0], cv2.boundingRect(c)[1]), cv2.FONT_HERSHEY_SIMPLEX, 0.4, (0, 255, 0), 1)

                choice = choices[bubbled] if bubbled is not None else ""
                
                # Highlight the chosen bubble in Green on debug image
                if bubbled is not None:
                     cv2.drawContours(output_img, [row[bubbled]], -1, (0, 255, 0), 3)

                real_results.append({
                    "question_number": current_q,
                    "marked_answer": choice,
                    "is_correct": False 
                })
                current_q += 1

        process_column(left_cnts, 1)
        process_column(right_cnts, 1 + len(real_results))

        # Save Debug Image
        filename = os.path.basename(image_path)
        debug_filename = "debug_" + filename
        debug_path = os.path.join(os.path.dirname(image_path), debug_filename)
        cv2.imwrite(debug_path, output_img)

        return {
            "success": True, 
            "message": f"Processed. Found {len(questionCnts)} bubbles.",
            "detected_questions": len(real_results),
            "answers": real_results,
            "debug_image": debug_filename
        }

    except Exception as e:
        import traceback
        return {"error": str(e) + traceback.format_exc()}

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(json.dumps({"error": "Missing image path"}))
        sys.exit(1)

    image_path = sys.argv[1]
    if not os.path.exists(image_path):
        print(json.dumps({"error": "File not found"}))
        sys.exit(1)

    result = process_omr(image_path)
    print(json.dumps(result))
